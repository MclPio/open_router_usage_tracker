# test/open_router_usage_tracker_test.rb
require "test_helper"

class OpenRouterUsageTrackerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!
    @sample_response = {
        "id" => "or-12345",
        "model" => "openai/gpt-4o",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 }
      }
    @openai_response = {
      "id" => "resp_67ccd2bed1ec8190b14f964abc0542670bb6a6b452d3795b",
      "object" => "response",
      "created_at" => 1741476542,
      "status" => "completed",
      "error" => nil,
      "incomplete_details" => nil,
      "instructions" => nil,
      "max_output_tokens" => nil,
      "model" => "gpt-4.1-2025-04-14",
      "output" => [
        {
          "type" => "message",
          "id" => "msg_67ccd2bf17f0819081ff3bb2cf6508e60bb6a6b452d3795b",
          "status" => "completed",
          "role" => "assistant",
          "content" => [
            {
              "type" => "output_text",
              "text" => "In a peaceful grove beneath a silver moon, a unicorn named Lumina discovered a hidden pool that reflected the stars. As she dipped her horn into the water, the pool began to shimmer, revealing a pathway to a magical realm of endless night skies. Filled with wonder, Lumina whispered a wish for all who dream to find their own hidden magic, and as she glanced back, her hoofprints sparkled like stardust.",
              "annotations" => []
            }
          ]
        }
      ],
      "parallel_tool_calls" => true,
      "previous_response_id" => nil,
      "reasoning" => {
        "effort" => nil,
        "summary" => nil
      },
      "store" => true,
      "temperature" => 1.0,
      "text" => {
        "format" => {
          "type" => "text"
        }
      },
      "tool_choice" => "auto",
      "tools" => [],
      "top_p" => 1.0,
      "truncation" => "disabled",
      "usage" => {
        "input_tokens" => 36,
        "input_tokens_details" => {
          "cached_tokens" => 0
        },
        "output_tokens" => 87,
        "output_tokens_details" => {
          "reasoning_tokens" => 0
        },
        "total_tokens" => 123
      },
      "user" => nil,
      "metadata" => {}
    }

    @openai_response_1 = {
      "id" => "resp_67ccd2bed1ec1490b14f964abc0542670bb6a6b452d3795b",
      "object" => "response",
      "created_at" => 1741476542,
      "status" => "completed",
      "error" => nil,
      "incomplete_details" => nil,
      "instructions" => nil,
      "max_output_tokens" => nil,
      "model" => "gpt-4.1-2025-04-14",
      "output" => [
        {
          "type" => "message",
          "id" => "msg_67ccd2bf14f0819081ff3bb2cf6508e60bb6a6b452d3795b",
          "status" => "completed",
          "role" => "assistant",
          "content" => [
            {
              "type" => "output_text",
              "text" => "In a peaceful grove beneath a silver moon, a unicorn named Lumina discovered a hidden pool that reflected the stars. As she dipped her horn into the water, the pool began to shimmer, revealing a pathway to a magical realm of endless night skies. Filled with wonder, Lumina whispered a wish for all who dream to find their own hidden magic, and as she glanced back, her hoofprints sparkled like stardust.",
              "annotations" => []
            }
          ]
        }
      ],
      "parallel_tool_calls" => true,
      "previous_response_id" => nil,
      "reasoning" => {
        "effort" => nil,
        "summary" => nil
      },
      "store" => true,
      "temperature" => 1.0,
      "text" => {
        "format" => {
          "type" => "text"
        }
      },
      "tool_choice" => "auto",
      "tools" => [],
      "top_p" => 1.0,
      "truncation" => "disabled",
      "usage" => {
        "input_tokens" => 36,
        "input_tokens_details" => {
          "cached_tokens" => 0
        },
        "output_tokens" => 87,
        "output_tokens_details" => {
          "reasoning_tokens" => 0
        },
        "total_tokens" => 123
      },
      "user" => nil,
      "metadata" => {}
    }

    @anthropic_response = {
      "id" => "msg_01XFDUDYJgAACzvnptvVoYEL",
      "type" => "message",
      "role" => "assistant",
      "content" => [
        {
          "type" => "text",
          "text" => "Hello!"
        }
      ],
      "model" => "claude-opus-4-20250514",
      "stop_reason" => "end_turn",
      "stop_sequence" => nil,
      "usage" => {
        "input_tokens" => 12,
        "output_tokens" => 6
      }
    }

    @google_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "The quick brown fox jumps over the lazy dog."
              }
            ],
            "role" => "model"
          },
          "finishReason" => "STOP",
          "index" => 0,
          "safetyRatings" => []
        }
      ],
      "usageMetadata" => {
        "promptTokenCount" => 10,
        "cachedContentTokenCount" => 0,
        "candidatesTokenCount" => 9,
        "toolUsePromptTokenCount" => 0,
        "thoughtsTokenCount" => 0,
        "totalTokenCount" => 19,
        "promptTokensDetails" => [
          {
            "modality" => "TEXT",
            "tokenCount" => 10
          }
        ],
        "cacheTokensDetails" => [],
        "candidatesTokensDetails" => [
          {
            "modality" => "TEXT",
            "tokenCount" => 9
          }
        ],
        "toolUsePromptTokensDetails" => []
      },
      "model" => "gemini-pro",
      "responseId" => "some-unique-google-id-12345"
    }

    @x_ai_response = {
      "id" => "a3d1008e-4544-40d4-d075-11527e794e4a",
      "object" => "chat.completion",
      "created" => 1752854522,
      "model" => "grok-4",
      "choices" => [
        {
          "index" => 0,
          "message" => {
            "role" => "assistant",
            "content" => "101 multiplied by 3 is 303.",
            "refusal" => nil
          },
          "finish_reason" => "stop"
        }
      ],
      "usage" => {
        "prompt_tokens" => 32,
        "completion_tokens" => 9,
        "total_tokens" => 135,
        "prompt_tokens_details" => {
          "text_tokens" => 32,
          "audio_tokens" => 0,
          "image_tokens" => 0,
          "cached_tokens" => 6
        },
        "completion_tokens_details" => {
          "reasoning_tokens" => 94,
          "audio_tokens" => 0,
          "accepted_prediction_tokens" => 0,
          "rejected_prediction_tokens" => 0
        },
        "num_sources_used" => 0
      },
      "system_fingerprint" => "fp_3a7881249c"
    }
  end

  test "log creates a new usage log record" do
    assert_difference "OpenRouterUsageTracker::UsageLog.count", 1 do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user)
    end

    log = OpenRouterUsageTracker::UsageLog.last
    assert_equal @user, log.user
    assert_equal "openai/gpt-4o", log.model
    assert_equal 30, log.total_tokens
  end

  test "accepts provider name" do
    assert_nothing_raised do
      OpenRouterUsageTracker.log(response: @openai_response, user: @user, provider: "open_ai")
    end
  end

  test "open_ai response is saved in UsageLog" do
    assert_difference("OpenRouterUsageTracker::UsageLog.count") do
      OpenRouterUsageTracker.log(response: @openai_response, user: @user, provider: "open_ai")
    end

    usage_log = OpenRouterUsageTracker::UsageLog.find_by(request_id: @openai_response["id"])

    assert_equal @openai_response.dig("model"), usage_log.model
    assert_equal @openai_response.dig("usage", "input_tokens"), usage_log.prompt_tokens
    assert_equal @openai_response.dig("usage", "output_tokens"), usage_log.completion_tokens
    assert_equal @openai_response.dig("usage", "total_tokens"), usage_log.total_tokens
    assert_equal 0, usage_log.cost
    assert_equal @user, usage_log.user
    assert_equal @openai_response.dig("id"), usage_log.request_id
    assert_equal @openai_response, usage_log.raw_usage_response
  end

  test "open_router response is saved in UsageLog" do
    assert_difference("OpenRouterUsageTracker::UsageLog.count") do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user, provider: "open_router")
    end

    usage_log = OpenRouterUsageTracker::UsageLog.find_by(request_id: @sample_response["id"])

    assert_equal @sample_response.dig("model"), usage_log.model
    assert_equal @sample_response.dig("usage", "prompt_tokens"), usage_log.prompt_tokens
    assert_equal @sample_response.dig("usage", "completion_tokens"), usage_log.completion_tokens
    assert_equal @sample_response.dig("usage", "total_tokens"), usage_log.total_tokens
    assert_equal @sample_response.dig("usage", "cost"), usage_log.cost
    assert_equal @user, usage_log.user
    assert_equal @sample_response.dig("id"), usage_log.request_id
    assert_equal @sample_response, usage_log.raw_usage_response
  end

  test "creates a new DailySummary on the first call of the day" do
    assert_difference [ "OpenRouterUsageTracker::UsageLog.count", "OpenRouterUsageTracker::DailySummary.count" ], 1 do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user, provider: "open_router")
    end

    summary = OpenRouterUsageTracker::DailySummary.last
    assert_equal @user, summary.user
    assert_equal Date.current, summary.day
    assert_equal @sample_response.dig("usage", "prompt_tokens"), summary.prompt_tokens
    assert_equal @sample_response.dig("usage", "completion_tokens"), summary.completion_tokens
    assert_equal @sample_response.dig("usage", "total_tokens"), summary.total_tokens
    assert_equal @sample_response.dig("usage", "cost"), summary.cost
  end

  test "updates an existing DailySummary on subsequent calls" do
    OpenRouterUsageTracker.log(response: @openai_response, user: @user, provider: "open_ai")

    # Assert that a new UsageLog is created, BUT a new DailySummary is NOT
    assert_difference "OpenRouterUsageTracker::UsageLog.count", 1 do
      assert_no_difference "OpenRouterUsageTracker::DailySummary.count" do
        # Second call with the same user on the same day
        OpenRouterUsageTracker.log(response: @openai_response_1, user: @user, provider: "open_ai")
      end
    end

    # Verify the summary's data has been aggregated correctly
    summary = OpenRouterUsageTracker::DailySummary.last
    assert_equal @user, summary.user

    # Expected = openai_response + openai_response_1
    assert_equal @openai_response.dig("usage", "input_tokens") + @openai_response_1.dig("usage", "input_tokens"), summary.prompt_tokens
    assert_equal @openai_response.dig("usage", "output_tokens") + @openai_response_1.dig("usage", "output_tokens"), summary.completion_tokens
    assert_equal @openai_response.dig("usage", "total_tokens") + @openai_response_1.dig("usage", "total_tokens"), summary.total_tokens
    assert_equal 0, summary.cost # 0 cost because open_ai does not return cost
  end

  test "stores raw response by default" do
    usage_log = OpenRouterUsageTracker.log(response: @sample_response, user: @user)
    assert_equal @sample_response, usage_log.raw_usage_response
  end

  test "stores raw response when store_raw_response is explicitly true" do
    usage_log = OpenRouterUsageTracker.log(response: @sample_response, user: @user, store_raw_response: true)
    assert_equal @sample_response, usage_log.raw_usage_response
  end

  test "does not store raw response when store_raw_response is false" do
    usage_log = OpenRouterUsageTracker.log(response: @sample_response, user: @user, store_raw_response: false)
    assert_equal({}, usage_log.raw_usage_response)
  end

  test "logs anthropic response" do
    usage_log = OpenRouterUsageTracker.log(response: @anthropic_response, user: @user, provider: "anthropic")

    assert_equal @anthropic_response["model"], usage_log.model
    assert_equal @anthropic_response["id"], usage_log.request_id
    assert_equal "anthropic", usage_log.provider
    assert_equal @user, usage_log.user
    assert_equal @anthropic_response, usage_log.raw_usage_response
    assert_equal @anthropic_response.dig("usage", "input_tokens"), usage_log.prompt_tokens
    assert_equal @anthropic_response.dig("usage", "output_tokens"), usage_log.completion_tokens
    assert_equal (@anthropic_response.dig("usage", "input_tokens").to_i +
                  @anthropic_response.dig("usage", "output_tokens").to_i),
                  usage_log.total_tokens
  end

  test "logs google response" do
    usage_log = OpenRouterUsageTracker.log(response: @google_response, user: @user, provider: "google")

    assert_equal @google_response["model"], usage_log.model
    assert_equal @google_response["responseId"], usage_log.request_id
    assert_equal "google", usage_log.provider
    assert_equal @user, usage_log.user
    assert_equal @google_response, usage_log.raw_usage_response
    assert_equal @google_response.dig("usageMetadata", "promptTokenCount"), usage_log.prompt_tokens
    assert_equal @google_response.dig("usageMetadata", "candidatesTokenCount"), usage_log.completion_tokens
    assert_equal @google_response.dig("usageMetadata", "totalTokenCount"), usage_log.total_tokens
  end

  test "logs XAi response" do
    usage_log = OpenRouterUsageTracker.log(response: @x_ai_response, user: @user, provider: "x_ai")

    assert_equal @x_ai_response.dig("model"), usage_log.model
    assert_equal @x_ai_response.dig("usage", "prompt_tokens"), usage_log.prompt_tokens
    assert_equal @x_ai_response.dig("usage", "completion_tokens"), usage_log.completion_tokens
    assert_equal @x_ai_response.dig("usage", "total_tokens"), usage_log.total_tokens
    assert_equal 0, usage_log.cost
    assert_equal "x_ai", usage_log.provider
    assert_equal @user, usage_log.user
    assert_equal @x_ai_response.dig("id"), usage_log.request_id
    assert_equal @x_ai_response, usage_log.raw_usage_response
  end

  # <-- PROVIDER TESTS -->
  test "log saved when you get 2 different providers with same request_id" do
    @sample_response["id"] = "mclpio-against-the-world"
    @openai_response["id"] = "mclpio-against-the-world"

    assert_difference "OpenRouterUsageTracker::UsageLog.count", 2 do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user, provider: "open_router")
      OpenRouterUsageTracker.log(response: @openai_response, user: @user, provider: "open_ai")
    end
  end

  test "log not saved when you get same providers and request_id" do
    @openai_response["id"] = "mclpio-against-the-world"
    @openai_response_1["id"] = "mclpio-against-the-world"

    OpenRouterUsageTracker.log(response: @openai_response, user: @user, provider: "open_ai")

    assert_raises "ActiveRecord::RecordInvalid" do
      OpenRouterUsageTracker.log(response: @openai_response_1, user: @user, provider: "open_ai")
    end
  end
end
