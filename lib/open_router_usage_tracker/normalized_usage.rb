require "open_router_usage_tracker/errors"

module OpenRouterUsageTracker
  class NormalizedUsage
    COST_SOURCES = [ "provider", "manual_response", "configured_pricing", "none" ].freeze

    attr_reader :model, :input_tokens, :output_tokens, :total_tokens,
                :cache_read_input_tokens, :cache_write_input_tokens, :reasoning_output_tokens,
                :cost_amount, :cost_currency, :cost_source, :request_id, :raw_usage_response, :details

    def initialize(model:, input_tokens:, output_tokens:, total_tokens:, request_id:, raw_usage_response:,
                   cache_read_input_tokens: 0, cache_write_input_tokens: 0, reasoning_output_tokens: 0,
                   cost_amount: 0, cost_currency: nil, cost_source: "none", details: {})
      @model = model
      @input_tokens = input_tokens
      @output_tokens = output_tokens
      @total_tokens = total_tokens
      @cache_read_input_tokens = cache_read_input_tokens
      @cache_write_input_tokens = cache_write_input_tokens
      @reasoning_output_tokens = reasoning_output_tokens
      @cost_amount = cost_amount
      @cost_currency = cost_currency
      @cost_source = cost_source
      @request_id = request_id
      @raw_usage_response = raw_usage_response
      @details = details || {}

      validate!
    end

    def to_log_attributes
      {
        model: model,
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        total_tokens: total_tokens,
        cache_read_input_tokens: cache_read_input_tokens,
        cache_write_input_tokens: cache_write_input_tokens,
        reasoning_output_tokens: reasoning_output_tokens,
        cost_amount: cost_amount,
        cost_currency: cost_currency,
        cost_source: cost_source,
        request_id: request_id,
        usage_details: details,
        raw_usage_response: raw_usage_response
      }
    end

    def to_h
      to_log_attributes.merge(details: details)
    end

    def with_cost(cost_amount:, cost_currency:, cost_source:)
      self.class.new(
        model: model,
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        total_tokens: total_tokens,
        cache_read_input_tokens: cache_read_input_tokens,
        cache_write_input_tokens: cache_write_input_tokens,
        reasoning_output_tokens: reasoning_output_tokens,
        cost_amount: cost_amount,
        cost_currency: cost_currency,
        cost_source: cost_source,
        request_id: request_id,
        raw_usage_response: raw_usage_response,
        details: details
      )
    end

    private

    def validate!
      require_present!(model, "model")
      require_present!(request_id, "request_id")
      validate_non_negative_integer!(input_tokens, "input_tokens")
      validate_non_negative_integer!(output_tokens, "output_tokens")
      validate_non_negative_integer!(total_tokens, "total_tokens")
      validate_non_negative_integer!(cache_read_input_tokens, "cache_read_input_tokens")
      validate_non_negative_integer!(cache_write_input_tokens, "cache_write_input_tokens")
      validate_non_negative_integer!(reasoning_output_tokens, "reasoning_output_tokens")
      validate_non_negative_number!(cost_amount, "cost_amount")
      validate_cost_source!
    end

    def require_present!(value, field)
      return unless value.nil? || (value.respond_to?(:empty?) && value.empty?)

      raise ParseError, "Missing required usage field: #{field}"
    end

    def validate_non_negative_integer!(value, field)
      raise ParseError, "Missing required usage field: #{field}" if value.nil?
      raise ParseError, "Invalid usage field #{field}: must be an Integer" unless value.is_a?(Integer)
      raise ParseError, "Invalid usage field #{field}: must be greater than or equal to 0" if value.negative?
    end

    def validate_non_negative_number!(value, field)
      raise ParseError, "Missing required usage field: #{field}" if value.nil?
      raise ParseError, "Invalid usage field #{field}: must be numeric" unless value.is_a?(Numeric)
      raise ParseError, "Invalid usage field #{field}: must be greater than or equal to 0" if value.negative?
    end

    def validate_cost_source!
      return if COST_SOURCES.include?(cost_source)

      raise ParseError, "Invalid usage field cost_source: must be one of #{COST_SOURCES.join(', ')}"
    end
  end
end
