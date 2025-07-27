module OpenRouterUsageTracker
  module Parsers
    class Anthropic
      def self.parse(response)
        input_tokens = response.dig("usage", "input_tokens")
        output_tokens = response.dig("usage", "output_tokens")
        total_tokens = input_tokens + output_tokens

        {
          model: response.dig("model"),
          prompt_tokens: input_tokens,
          completion_tokens: output_tokens,
          total_tokens: total_tokens,
          request_id: response["id"],
          raw_usage_response: response
        }
      end
    end
  end
end
