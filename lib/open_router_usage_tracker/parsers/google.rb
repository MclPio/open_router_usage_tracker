module OpenRouterUsageTracker
  module Parsers
    class Google
      def self.parse(response)
        {
          model: response.dig("model"),
          prompt_tokens: response.dig("usageMetadata", "promptTokenCount").to_i,
          completion_tokens: response.dig("usageMetadata", "candidatesTokenCount").to_i,
          total_tokens: response.dig("usageMetadata", "totalTokenCount").to_i,
          cost: response.dig("usage", "cost").to_f,
          request_id: response["responseId"],
          raw_usage_response: response
        }
      end
    end
  end
end
