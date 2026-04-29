require "open_router_usage_tracker/persistence/daily_summary_updater"
require "set"

module OpenRouterUsageTracker
  module Maintenance
    class DailySummaryRebuilder
      def self.call(scope: nil)
        new(
          scope: scope || OpenRouterUsageTracker::UsageLog.all,
          full_rebuild: scope.nil?
        ).call
      end

      def initialize(scope:, full_rebuild:)
        @scope = scope
        @full_rebuild = full_rebuild
      end

      def call
        delete_summaries
        rebuilt_count = 0

        scope.find_each do |usage_log|
          OpenRouterUsageTracker::Persistence::DailySummaryUpdater.call(usage_log)
          rebuilt_count += 1
        end

        rebuilt_count
      end

      private

      attr_reader :scope, :full_rebuild

      def delete_summaries
        if full_rebuild
          OpenRouterUsageTracker::DailySummary.delete_all
        else
          delete_summaries_for_scope
        end
      end

      def delete_summaries_for_scope
        deleted_keys = Set.new

        scope.find_each do |usage_log|
          key = summary_key_for(usage_log)
          next unless deleted_keys.add?(key)

          OpenRouterUsageTracker::DailySummary.where(
            user: usage_log.user,
            day: usage_log.occurred_at.to_date,
            provider: usage_log.provider,
            model: usage_log.model
          ).delete_all
        end
      end

      def summary_key_for(usage_log)
        [
          usage_log.user_type,
          usage_log.user_id,
          usage_log.occurred_at.to_date,
          usage_log.provider,
          usage_log.model
        ]
      end
    end
  end
end
