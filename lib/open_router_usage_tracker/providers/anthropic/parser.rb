require "open_router_usage_tracker/providers/base_parser"

module OpenRouterUsageTracker
  module Providers
    module Anthropic
      class Parser < BaseParser
        def self.parse(response)
          required_hash(response, "usage")
          input_tokens = required_integer(response, "usage", "input_tokens")
          cache_creation_input_tokens = optional_integer(response, "usage", "cache_creation_input_tokens").to_i
          cache_read_input_tokens = optional_integer(response, "usage", "cache_read_input_tokens").to_i
          prompt_tokens = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
          output_tokens = required_integer(response, "usage", "output_tokens")
          total_tokens = prompt_tokens + output_tokens

          normalized_usage(
            model: required_path(response, "model"),
            input_tokens: prompt_tokens,
            output_tokens: output_tokens,
            total_tokens: total_tokens,
            cache_read_input_tokens: cache_read_input_tokens,
            cache_write_input_tokens: cache_creation_input_tokens,
            **cost_attributes(response, source: "manual_response"),
            request_id: required_path(response, "id"),
            raw_usage_response: response,
            details: compact_details(
              "input_tokens" => optional_path(response, "usage", "input_tokens"),
              "cache_creation_input_tokens" => optional_path(response, "usage", "cache_creation_input_tokens"),
              "cache_read_input_tokens" => optional_path(response, "usage", "cache_read_input_tokens"),
              "output_tokens" => optional_path(response, "usage", "output_tokens"),
              "service_tier" => optional_path(response, "usage", "service_tier")
            )
          )
        end
      end
    end
  end
end
