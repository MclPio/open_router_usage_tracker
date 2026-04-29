require "test_helper"
require "json"

class ProviderParserContractTest < ActiveSupport::TestCase
  FIXTURE_ROOT = File.expand_path("../fixtures/provider_responses", __dir__)

  test "open_router fixture satisfies the normalized usage contract" do
    usage = parse_fixture("open_router_chat_completion", OpenRouterUsageTracker::Providers::OpenRouter::Parser)

    assert_normalized_usage usage,
                            model: "openai/gpt-4o",
                            request_id: "or-usage-001",
                            input_tokens: 194,
                            output_tokens: 2,
                            total_tokens: 196,
                            cost_amount: 0.95
    assert_equal 12, usage.details.dig("prompt_tokens_details", "cached_tokens")
    assert_equal 19, usage.details.dig("cost_details", "upstream_inference_cost")
    assert_equal 12, usage.cache_read_input_tokens
    assert_equal 100, usage.cache_write_input_tokens
    assert_equal "credits", usage.cost_currency
    assert_equal "provider", usage.cost_source
  end

  test "open_ai responses api fixture satisfies the normalized usage contract" do
    usage = parse_fixture("open_ai_responses_api", OpenRouterUsageTracker::Providers::OpenAi::Parser)

    assert_normalized_usage usage,
                            model: "gpt-5.1",
                            request_id: "resp-openai-001",
                            input_tokens: 139,
                            output_tokens: 438,
                            total_tokens: 577,
                            cost_amount: 0.0
    assert_equal 7, usage.details.dig("input_tokens_details", "cached_tokens")
    assert_equal 64, usage.details.dig("output_tokens_details", "reasoning_tokens")
    assert_equal 7, usage.cache_read_input_tokens
    assert_equal 64, usage.reasoning_output_tokens
  end

  test "open_ai chat completions fixture satisfies the normalized usage contract" do
    usage = parse_fixture("open_ai_chat_completion", OpenRouterUsageTracker::Providers::OpenAi::Parser)

    assert_normalized_usage usage,
                            model: "gpt-4o-2024-08-06",
                            request_id: "chatcmpl-openai-001",
                            input_tokens: 1117,
                            output_tokens: 46,
                            total_tokens: 1163,
                            cost_amount: 0.0
    assert_equal "default", usage.details["service_tier"]
    assert_equal 0, usage.details.dig("completion_tokens_details", "reasoning_tokens")
  end

  test "anthropic fixture includes cache tokens in prompt and total tokens" do
    usage = parse_fixture("anthropic_message_service_tier", OpenRouterUsageTracker::Providers::Anthropic::Parser)

    assert_normalized_usage usage,
                            model: "claude-opus-4-1-20250805",
                            request_id: "msg-anthropic-001",
                            input_tokens: 460,
                            output_tokens: 585,
                            total_tokens: 1045,
                            cost_amount: 0.0
    assert_equal 20, usage.details["cache_creation_input_tokens"]
    assert_equal 30, usage.details["cache_read_input_tokens"]
    assert_equal "priority", usage.details["service_tier"]
    assert_equal 20, usage.cache_write_input_tokens
    assert_equal 30, usage.cache_read_input_tokens
  end

  test "google fixture satisfies the normalized usage contract" do
    usage = parse_fixture("google_generate_content", OpenRouterUsageTracker::Providers::Google::Parser)

    assert_normalized_usage usage,
                            model: "gemini-2.5-pro",
                            request_id: "google-response-001",
                            input_tokens: 10,
                            output_tokens: 9,
                            total_tokens: 21,
                            cost_amount: 0.0
    assert_equal 4, usage.details["cached_content_token_count"]
    assert_equal 2, usage.details["thoughts_token_count"]
    assert_equal "TEXT", usage.details.dig("prompt_tokens_details", 0, "modality")
    assert_equal 4, usage.cache_read_input_tokens
    assert_equal 2, usage.reasoning_output_tokens
  end

  test "x_ai chat completions fixture satisfies the normalized usage contract" do
    usage = parse_fixture("x_ai_chat_completion", OpenRouterUsageTracker::Providers::XAi::Parser)

    assert_normalized_usage usage,
                            model: "grok-4",
                            request_id: "xai-chat-001",
                            input_tokens: 125,
                            output_tokens: 48,
                            total_tokens: 173,
                            cost_amount: 0.0
    assert_equal 98, usage.details.dig("prompt_tokens_details", "cached_tokens")
    assert_equal 98, usage.cache_read_input_tokens
  end

  test "x_ai responses api fixture satisfies the normalized usage contract" do
    usage = parse_fixture("x_ai_responses_api", OpenRouterUsageTracker::Providers::XAi::Parser)

    assert_normalized_usage usage,
                            model: "grok-4",
                            request_id: "xai-resp-001",
                            input_tokens: 125,
                            output_tokens: 48,
                            total_tokens: 173,
                            cost_amount: 0.0
    assert_equal 98, usage.details.dig("input_tokens_details", "cached_tokens")
  end

  test "provider parsers accept symbol keyed provider responses" do
    response = fixture("open_ai_responses_api").deep_symbolize_keys
    usage = OpenRouterUsageTracker::Providers::OpenAi::Parser.parse(response)

    assert_equal "resp-openai-001", usage.request_id
    assert_equal 139, usage.input_tokens
    assert_equal 7, usage.details.dig("input_tokens_details", :cached_tokens)
  end

  test "parser raises explicit error when required model is missing" do
    response = fixture("open_router_chat_completion")
    response.delete("model")

    error = assert_raises(OpenRouterUsageTracker::ParseError) do
      OpenRouterUsageTracker::Providers::OpenRouter::Parser.parse(response)
    end

    assert_match "model", error.message
  end

  test "parser raises explicit error when required usage object is missing" do
    response = fixture("open_router_chat_completion")
    response.delete("usage")

    error = assert_raises(OpenRouterUsageTracker::ParseError) do
      OpenRouterUsageTracker::Providers::OpenRouter::Parser.parse(response)
    end

    assert_match "usage", error.message
  end

  test "parser raises explicit error when token field is not numeric" do
    response = fixture("open_router_chat_completion")
    response["usage"]["prompt_tokens"] = "many"

    error = assert_raises(OpenRouterUsageTracker::ParseError) do
      OpenRouterUsageTracker::Providers::OpenRouter::Parser.parse(response)
    end

    assert_match "usage.prompt_tokens", error.message
  end

  test "log does not persist anything when parser validation fails" do
    user = User.create!
    response = fixture("open_router_chat_completion")
    response.delete("usage")

    assert_no_difference [ "OpenRouterUsageTracker::UsageLog.count", "OpenRouterUsageTracker::DailySummary.count" ] do
      assert_raises(OpenRouterUsageTracker::ParseError) do
        OpenRouterUsageTracker.log(response: response, user: user, provider: "open_router")
      end
    end
  end

  private

  def parse_fixture(name, parser)
    parser.parse(fixture(name))
  end

  def fixture(name)
    JSON.parse(File.read(File.join(FIXTURE_ROOT, "#{name}.json")))
  end

  def assert_normalized_usage(usage, model:, request_id:, input_tokens:, output_tokens:, total_tokens:, cost_amount:)
    assert_instance_of OpenRouterUsageTracker::NormalizedUsage, usage
    assert_equal model, usage.model
    assert_equal request_id, usage.request_id
    assert_equal input_tokens, usage.input_tokens
    assert_equal output_tokens, usage.output_tokens
    assert_equal total_tokens, usage.total_tokens
    assert_equal cost_amount, usage.cost_amount
    assert_equal usage.raw_usage_response, usage.to_log_attributes[:raw_usage_response]
  end
end
