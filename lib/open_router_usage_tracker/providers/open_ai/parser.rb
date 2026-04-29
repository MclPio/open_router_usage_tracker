require "open_router_usage_tracker/providers/base_parser"

module OpenRouterUsageTracker
  module Providers
    module OpenAi
      class Parser < BaseParser
        def self.parse(response)
          required_hash(response, "usage")
          prompt_tokens = required_token_count(response, paths: [
            [ "usage", "input_tokens" ],
            [ "usage", "prompt_tokens" ]
          ], field: "usage.input_tokens or usage.prompt_tokens")
          completion_tokens = required_token_count(response, paths: [
            [ "usage", "output_tokens" ],
            [ "usage", "completion_tokens" ]
          ], field: "usage.output_tokens or usage.completion_tokens")
          total_tokens = optional_integer(response, "usage", "total_tokens") || prompt_tokens + completion_tokens

          normalized_usage(
            model: required_path(response, "model"),
            input_tokens: prompt_tokens,
            output_tokens: completion_tokens,
            total_tokens: total_tokens,
            cache_read_input_tokens: optional_token_count(response, paths: [
              [ "usage", "input_tokens_details", "cached_tokens" ],
              [ "usage", "prompt_tokens_details", "cached_tokens" ]
            ], field: "cached_tokens").to_i,
            reasoning_output_tokens: optional_token_count(response, paths: [
              [ "usage", "output_tokens_details", "reasoning_tokens" ],
              [ "usage", "completion_tokens_details", "reasoning_tokens" ]
            ], field: "reasoning_tokens").to_i,
            **cost_attributes(response, source: "manual_response"),
            request_id: required_path(response, "id"),
            raw_usage_response: response,
            details: compact_details(
              "input_tokens_details" => optional_path(response, "usage", "input_tokens_details"),
              "output_tokens_details" => optional_path(response, "usage", "output_tokens_details"),
              "prompt_tokens_details" => optional_path(response, "usage", "prompt_tokens_details"),
              "completion_tokens_details" => optional_path(response, "usage", "completion_tokens_details"),
              "service_tier" => optional_path(response, "service_tier")
            )
          )
        end
      end
    end
  end
end
