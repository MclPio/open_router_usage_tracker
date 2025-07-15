require "open_router_usage_tracker/version"
require "open_router_usage_tracker/engine"
require "open_router_usage_tracker/adapter/base"

module OpenRouterUsageTracker
  class << self
    attr_writer :configuration

    def log(response:, user:, provider: nil)
      ApplicationRecord.transaction do
        usage_log = create_usage_log(response, user)
        update_daily_summary(usage_log)
        usage_log
      end
    end

    private

    def create_usage_log(response, user)
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

    def update_daily_summary(usage_log)
      summary = OpenRouterUsageTracker::DailySummary.find_or_initialize_by(
        user: usage_log.user,
        day: Date.current
      )
      summary.total_tokens += usage_log.total_tokens
      summary.cost += usage_log.cost
      summary.save!
    end
  end
end
