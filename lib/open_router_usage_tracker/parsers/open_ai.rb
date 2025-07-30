module OpenRouterUsageTracker
  module Parsers
    class OpenAi
      def self.parse(response)
        {
          model: response.dig("model"),
          prompt_tokens: response.dig("usage", "input_tokens").to_i,
          completion_tokens: response.dig("usage", "output_tokens").to_i,
          total_tokens: response.dig("usage", "total_tokens").to_i,
          cost: response.dig("usage", "cost").to_f,
          request_id: response["id"],
          raw_usage_response: response
        }
      end
    end
  end
end
