require "open_router_usage_tracker/providers/base_parser"

module OpenRouterUsageTracker
  module Providers
    module OpenRouter
      class Parser < BaseParser
        def self.parse(response)
          required_hash(response, "usage")
          input_tokens = required_integer(response, "usage", "prompt_tokens")
          output_tokens = required_integer(response, "usage", "completion_tokens")

          normalized_usage(
            model: required_path(response, "model"),
            input_tokens: input_tokens,
            output_tokens: output_tokens,
            total_tokens: required_integer(response, "usage", "total_tokens"),
            cache_read_input_tokens: optional_integer(response, "usage", "prompt_tokens_details", "cached_tokens").to_i,
            cache_write_input_tokens: optional_integer(response, "usage", "prompt_tokens_details", "cache_write_tokens").to_i,
            reasoning_output_tokens: optional_integer(response, "usage", "completion_tokens_details", "reasoning_tokens").to_i,
            **cost_attributes(response, source: "provider", currency: "credits"),
            request_id: required_path(response, "id"),
            raw_usage_response: response,
            details: compact_details(
              "prompt_tokens_details" => optional_path(response, "usage", "prompt_tokens_details"),
              "completion_tokens_details" => optional_path(response, "usage", "completion_tokens_details"),
              "cost_details" => optional_path(response, "usage", "cost_details")
            )
          )
        end
      end
    end
  end
end
