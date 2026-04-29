require "test_helper"
require "bigdecimal"

class CostCalculatorTest < ActiveSupport::TestCase
  setup do
    @previous_configuration = OpenRouterUsageTracker.configuration
    OpenRouterUsageTracker.configuration = OpenRouterUsageTracker::Configuration.new
  end

  teardown do
    OpenRouterUsageTracker.configuration = @previous_configuration
  end

  test "leaves usage unchanged when no pricing is configured" do
    usage = normalized_usage

    calculated = OpenRouterUsageTracker::CostCalculator.call(usage, provider: "open_ai")

    assert_same usage, calculated
    assert_equal 0, calculated.cost_amount
    assert_equal "none", calculated.cost_source
  end

  test "calculates configured input and output token cost" do
    OpenRouterUsageTracker.configuration.pricing = {
      "open_ai" => {
        "gpt-test" => {
          "input_cost_per_million" => 2.0,
          "output_cost_per_million" => 4.0,
          "currency" => "USD"
        }
      }
    }
    usage = normalized_usage(input_tokens: 1_000_000, output_tokens: 500_000)

    calculated = OpenRouterUsageTracker::CostCalculator.call(usage, provider: "open_ai")

    assert_equal BigDecimal("4.0"), calculated.cost_amount
    assert_equal "USD", calculated.cost_currency
    assert_equal "configured_pricing", calculated.cost_source
  end

  test "calculates cache and reasoning token modifiers without double counting base tokens" do
    OpenRouterUsageTracker.configuration.pricing = {
      open_ai: {
        "gpt-test" => {
          input_cost_per_million: 1.0,
          output_cost_per_million: 2.0,
          cache_read_input_cost_per_million: 0.25,
          cache_write_input_cost_per_million: 1.5,
          reasoning_output_cost_per_million: 3.0,
          currency: "USD"
        }
      }
    }
    usage = normalized_usage(
      input_tokens: 1_000,
      output_tokens: 500,
      cache_read_input_tokens: 200,
      cache_write_input_tokens: 100,
      reasoning_output_tokens: 50
    )

    calculated = OpenRouterUsageTracker::CostCalculator.call(usage, provider: "open_ai")

    assert_equal BigDecimal("0.00195"), calculated.cost_amount
  end

  test "does not override provider or manual response costs" do
    OpenRouterUsageTracker.configuration.pricing = {
      "open_router" => {
        "gpt-test" => {
          "input_cost_per_million" => 1.0,
          "output_cost_per_million" => 1.0,
          "currency" => "USD"
        }
      }
    }
    usage = normalized_usage(cost_amount: 0.5, cost_currency: "credits", cost_source: "provider")

    calculated = OpenRouterUsageTracker::CostCalculator.call(usage, provider: "open_router")

    assert_same usage, calculated
    assert_equal 0.5, calculated.cost_amount
    assert_equal "credits", calculated.cost_currency
    assert_equal "provider", calculated.cost_source
  end

  test "log stores configured pricing cost on usage log and daily summary" do
    OpenRouterUsageTracker.configuration.pricing = {
      "open_ai" => {
        "gpt-4.1-2025-04-14" => {
          "input_cost_per_million" => 10.0,
          "output_cost_per_million" => 20.0,
          "currency" => "USD"
        }
      }
    }
    user = User.create!
    response = {
      "id" => "resp-priced-001",
      "model" => "gpt-4.1-2025-04-14",
      "usage" => {
        "input_tokens" => 36,
        "output_tokens" => 87,
        "total_tokens" => 123
      }
    }

    usage_log = OpenRouterUsageTracker.log(response: response, user: user, provider: "open_ai")

    assert_equal BigDecimal("0.0021"), usage_log.cost_amount
    assert_equal "USD", usage_log.cost_currency
    assert_equal "configured_pricing", usage_log.cost_source

    summary = user.daily_usage_summary_for(day: Date.current, provider: "open_ai", model: "gpt-4.1-2025-04-14")
    assert_equal BigDecimal("0.0021"), summary.cost_amount
    assert_equal "USD", summary.cost_currency
    assert_equal "configured_pricing", summary.cost_source
  end

  private

  def normalized_usage(
    input_tokens: 1_000,
    output_tokens: 500,
    total_tokens: input_tokens + output_tokens,
    cache_read_input_tokens: 0,
    cache_write_input_tokens: 0,
    reasoning_output_tokens: 0,
    cost_amount: 0,
    cost_currency: nil,
    cost_source: "none"
  )
    OpenRouterUsageTracker::NormalizedUsage.new(
      model: "gpt-test",
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      total_tokens: total_tokens,
      cache_read_input_tokens: cache_read_input_tokens,
      cache_write_input_tokens: cache_write_input_tokens,
      reasoning_output_tokens: reasoning_output_tokens,
      cost_amount: cost_amount,
      cost_currency: cost_currency,
      cost_source: cost_source,
      request_id: SecureRandom.uuid,
      raw_usage_response: {},
      details: {}
    )
  end
end
