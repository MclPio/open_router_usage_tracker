require "bigdecimal"
require "open_router_usage_tracker/configuration"

module OpenRouterUsageTracker
  class CostCalculator
    TOKENS_PER_MILLION = BigDecimal("1000000")

    def self.call(normalized_usage, provider:)
      new(normalized_usage, provider: provider).call
    end

    def initialize(normalized_usage, provider:)
      @normalized_usage = normalized_usage
      @provider = provider
    end

    def call
      return normalized_usage unless normalized_usage.cost_source == "none"
      return normalized_usage unless pricing

      cost_amount = calculate_cost
      return normalized_usage if cost_amount.zero?

      normalized_usage.with_cost(
        cost_amount: cost_amount,
        cost_currency: pricing_value("currency"),
        cost_source: "configured_pricing"
      )
    end

    private

    attr_reader :normalized_usage, :provider

    def pricing
      @pricing ||= OpenRouterUsageTracker.configuration.pricing_for(provider, normalized_usage.model)
    end

    def calculate_cost
      input_cost + output_cost + cache_read_input_cost + cache_write_input_cost + reasoning_output_cost
    end

    def input_cost
      rate = decimal_pricing_value("input_cost_per_million")
      return BigDecimal("0") unless rate

      tokens = normalized_usage.input_tokens
      tokens -= normalized_usage.cache_read_input_tokens if decimal_pricing_value("cache_read_input_cost_per_million")
      tokens -= normalized_usage.cache_write_input_tokens if decimal_pricing_value("cache_write_input_cost_per_million")

      cost_for_tokens([ tokens, 0 ].max, rate)
    end

    def output_cost
      rate = decimal_pricing_value("output_cost_per_million")
      return BigDecimal("0") unless rate

      tokens = normalized_usage.output_tokens
      tokens -= normalized_usage.reasoning_output_tokens if decimal_pricing_value("reasoning_output_cost_per_million")

      cost_for_tokens([ tokens, 0 ].max, rate)
    end

    def cache_read_input_cost
      cost_for_optional_tokens(
        normalized_usage.cache_read_input_tokens,
        "cache_read_input_cost_per_million"
      )
    end

    def cache_write_input_cost
      cost_for_optional_tokens(
        normalized_usage.cache_write_input_tokens,
        "cache_write_input_cost_per_million"
      )
    end

    def reasoning_output_cost
      cost_for_optional_tokens(
        normalized_usage.reasoning_output_tokens,
        "reasoning_output_cost_per_million"
      )
    end

    def cost_for_optional_tokens(tokens, pricing_key)
      rate = decimal_pricing_value(pricing_key)
      return BigDecimal("0") unless rate

      cost_for_tokens(tokens, rate)
    end

    def cost_for_tokens(tokens, rate)
      BigDecimal(tokens.to_s) * rate / TOKENS_PER_MILLION
    end

    def decimal_pricing_value(key)
      value = pricing_value(key)
      value.nil? ? nil : BigDecimal(value.to_s)
    end

    def pricing_value(key)
      pricing[key] || pricing[key.to_sym]
    end
  end
end
