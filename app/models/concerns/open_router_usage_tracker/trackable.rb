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

    # Calculates the total cost from the daily summaries within a given date range.
    # It can be filtered by provider and, optionally, by model.
    #
    # @param range [Range<Date>] The date range to query (e.g., 1.month.ago.to_date..Date.current).
    # @param provider [String] The provider name (e.g., 'open_ai').
    # @param model [String, nil] The optional model name.
    # @return [BigDecimal] The total cost.
    def total_cost_in_range(range, provider:, model: nil)
      summaries = daily_summaries.where(day: range, provider: provider)
      summaries = summaries.where(model: model) if model
      summaries.sum(:cost)
    end
  end
end
