module OpenRouterUsageTracker
  module Parsers
    class OpenAi
      def self.parse(response)
        {
          model: response.dig("model"),
          prompt_tokens: response.dig("usage", "input_tokens"),
          completion_tokens: response.dig("usage", "output_tokens"),
          total_tokens: response.dig("usage", "total_tokens"),
          request_id: response["id"],
          raw_usage_response: response
        }
      end
    end
  end
end
