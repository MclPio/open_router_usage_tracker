module OpenRouterUsageTracker
  module Parsers
    class OpenRouter
      def self.parse(response)
        {
          model: response.dig("model"),
          prompt_tokens: response.dig("usage", "prompt_tokens"),
          completion_tokens: response.dig("usage", "completion_tokens"),
          total_tokens: response.dig("usage", "total_tokens"),
          cost: response.dig("usage", "cost"),
          request_id: response.dig("id"),
          raw_usage_response: response
        }
      end
    end
  end
end
