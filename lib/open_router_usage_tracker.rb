require "open_router_usage_tracker/version"
require "open_router_usage_tracker/railtie"
require "open_router_usage_tracker/engine"

module OpenRouterUsageTracker
  class << self
    attr_writer :configuration

    def log(response:, user:)
      attributes = {
        model: response["model"],
        prompt_tokens: response.dig("usage", "prompt_tokens"),
        completion_tokens: response.dig("usage", "completion_tokens"),
        total_tokens: response.dig("usage", "total_tokens"),
        cost: response.dig("usage", "cost"),
        request_id: response["id"],
        raw_usage_response: response,
        user: user
      }

      OpenRouterUsageTracker::UsageLog.create!(attributes)
    end
  end
end
