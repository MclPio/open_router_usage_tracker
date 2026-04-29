module OpenRouterUsageTracker
  module Maintenance
    class RawResponsePruner
      def self.call(before:)
        new(before: before).call
      end

      def initialize(before:)
        @before = before
      end

      def call
        OpenRouterUsageTracker::UsageLog.where("occurred_at < ?", before).update_all(raw_usage_response: {})
      end

      private

      attr_reader :before
    end
  end
end
