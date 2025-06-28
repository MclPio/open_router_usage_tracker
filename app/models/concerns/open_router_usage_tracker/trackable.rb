require "active_support/concern"

module OpenRouterUsageTracker
  module Trackable
    extend ActiveSupport::Concern

    included do
      has_many :usage_logs, as: :user, class_name: "OpenRouterUsageTracker::UsageLog", dependent: :destroy
      has_many :daily_summaries, as: :user, class_name: "OpenRouterUsageTracker::DailySummary", dependent: :destroy
    end

    def usage_today
      daily_summaries.find_by(day: Date.current)
    end

    def cost_exceeded?(limit:, period: :daily)
      case period
      when :daily
        usage_today&.cost.to_d > limit
      else
        raise ArgumentError, "Unsupported period: #{period}"
      end
    end

    # A flexible method to query usage within any time period.
    #
    # Example:
    #   user.usage_in_period(24.hours.ago..Time.current)
    #   => { tokens: 1500, cost: 0.025 }
    #
    def usage_in_period(range)
      logs_in_range = self.usage_logs.where(created_at: range)

      # Use .to_i and .to_d to handle cases where there are no logs (sum returns nil)
      total_tokens = logs_in_range.sum(:total_tokens).to_i
      total_cost = logs_in_range.sum(:cost).to_d

      { tokens: total_tokens, cost: total_cost }
    end

    # A convenience method for checking the last 24 hours.
    def usage_in_last_24_hours
      usage_in_period(24.hours.ago..Time.current)
    end
  end
end
