module OpenRouterUsageTracker
  module Parsers
    class Anthropic
      def self.parse(response)
        input_tokens = response.dig("usage", "input_tokens").to_i
        cache_creation_input_tokens = response.dig("usage", "cache_creation_input_tokens").to_i
        cache_read_input_tokens = response.dig("usage", "cache_read_input_tokens").to_i
        prompt_tokens = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
        output_tokens = response.dig("usage", "output_tokens").to_i
        total_tokens = prompt_tokens + output_tokens

        {
          model: response.dig("model"),
          prompt_tokens: prompt_tokens,
          completion_tokens: output_tokens,
          total_tokens: total_tokens,
          cost: response.dig("usage", "cost").to_f,
          request_id: response["id"],
          raw_usage_response: response
        }
      end
    end
  end
end
