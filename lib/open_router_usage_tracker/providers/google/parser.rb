require "open_router_usage_tracker/providers/base_parser"

module OpenRouterUsageTracker
  module Providers
    module Google
      class Parser < BaseParser
        def self.parse(response)
          required_hash(response, "usageMetadata")

          normalized_usage(
            model: required_path(response, "model"),
            input_tokens: required_integer(response, "usageMetadata", "promptTokenCount"),
            output_tokens: required_integer(response, "usageMetadata", "candidatesTokenCount"),
            total_tokens: required_integer(response, "usageMetadata", "totalTokenCount"),
            cache_read_input_tokens: optional_integer(response, "usageMetadata", "cachedContentTokenCount").to_i,
            reasoning_output_tokens: optional_integer(response, "usageMetadata", "thoughtsTokenCount").to_i,
            **cost_attributes(response, source: "manual_response"),
            request_id: required_path(response, "responseId"),
            raw_usage_response: response,
            details: compact_details(
              "cached_content_token_count" => optional_path(response, "usageMetadata", "cachedContentTokenCount"),
              "tool_use_prompt_token_count" => optional_path(response, "usageMetadata", "toolUsePromptTokenCount"),
              "thoughts_token_count" => optional_path(response, "usageMetadata", "thoughtsTokenCount"),
              "prompt_tokens_details" => optional_path(response, "usageMetadata", "promptTokensDetails"),
              "cache_tokens_details" => optional_path(response, "usageMetadata", "cacheTokensDetails"),
              "candidates_tokens_details" => optional_path(response, "usageMetadata", "candidatesTokensDetails"),
              "tool_use_prompt_tokens_details" => optional_path(response, "usageMetadata", "toolUsePromptTokensDetails")
            )
          )
        end
      end
    end
  end
end
