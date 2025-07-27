module OpenRouterUsageTracker
  module Parsers
    class Google
      def self.parse(response)
        {
          model: response.dig("model"),
          prompt_tokens: response.dig("usageMetadata", "promptTokenCount"),
          completion_tokens: response.dig("usageMetadata", "candidatesTokenCount"),
          total_tokens: response.dig("usageMetadata", "totalTokenCount"),
          request_id: response["responseId"],
          raw_usage_response: response
        }
      end
    end
  end
end
