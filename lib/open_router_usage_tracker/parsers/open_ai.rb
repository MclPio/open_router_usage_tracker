module OpenRouterUsageTracker
  module Parsers
    class OpenAi
      def self.parse(response)
        prompt_tokens = response.dig("usage", "input_tokens") || response.dig("usage", "prompt_tokens")
        completion_tokens = response.dig("usage", "output_tokens") || response.dig("usage", "completion_tokens")
        total_tokens = response.dig("usage", "total_tokens") || prompt_tokens.to_i + completion_tokens.to_i

        {
          model: response.dig("model"),
          prompt_tokens: prompt_tokens.to_i,
          completion_tokens: completion_tokens.to_i,
          total_tokens: total_tokens.to_i,
          cost: response.dig("usage", "cost").to_f,
          request_id: response["id"],
          raw_usage_response: response
        }
      end
    end
  end
end
