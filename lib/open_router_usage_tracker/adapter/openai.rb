module OpenRouterUsageTracker
  module Parsers
    module OpenAI
      def self.parse(response)
        # Logic to parse an OpenAI/OpenRouter response
        # ...
        {
          model_name: response["model"],
          prompt_tokens: response.dig("usage", "prompt_tokens"),
          completion_tokens: response.dig("usage", "completion_tokens"),
          total_tokens: response.dig("usage", "total_tokens"),
          cost: response.dig("usage", "cost"),
          request_id: response["id"]
        }
      end
    end
  end
end
