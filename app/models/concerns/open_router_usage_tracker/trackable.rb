require "active_support/concern"

module OpenRouterUsageTracker
  module Trackable
    extend ActiveSupport::Concern

    included do
      has_many :usage_logs, as: :user, class_name: "OpenRouterUsageTracker::UsageLog"
      has_many :daily_summaries, as: :user, class_name: "OpenRouterUsageTracker::DailySummary"
    end

    # Finds a specific daily summary for a given day, provider, and model.
    # This is the primary, high-performance method for usage checks.
    #
    # @param day [Date] The date to check. Pass `Time.zone.today` to be timezone-aware.
    # @param provider [String] The provider name (e.g., 'open_router').
    # @param model [String] The model name (e.g., 'openai/gpt-4o').
    # @return [OpenRouterUsageTracker::DailySummary, nil]
    def daily_usage_summary_for(day:, provider:, model:)
      daily_summaries.find_by(day: day, provider: provider, model: model)
    end
  end
end
