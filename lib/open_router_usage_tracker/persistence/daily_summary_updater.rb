module OpenRouterUsageTracker
  module Persistence
    class DailySummaryUpdater
      def self.call(usage_log)
        new(usage_log).call
      end

      def initialize(usage_log)
        @usage_log = usage_log
      end

      def call
        summary = OpenRouterUsageTracker::DailySummary.create_or_find_by!(
          user: usage_log.user,
          day: usage_log.occurred_at.to_date,
          provider: usage_log.provider,
          model: usage_log.model
        )

        summary.with_lock do
          summary.input_tokens += usage_log.input_tokens
          summary.output_tokens += usage_log.output_tokens
          summary.total_tokens += usage_log.total_tokens
          summary.cache_read_input_tokens += usage_log.cache_read_input_tokens
          summary.cache_write_input_tokens += usage_log.cache_write_input_tokens
          summary.reasoning_output_tokens += usage_log.reasoning_output_tokens
          summary.cost_amount += usage_log.cost_amount
          summary.cost_currency = merge_cost_currency(summary.cost_currency, usage_log.cost_currency)
          summary.cost_source = merge_cost_source(summary.cost_source, usage_log.cost_source)
          summary.usage_details = merge_numeric_details(summary.usage_details, usage_log.usage_details)
          summary.save!
        end
      end

      private

      attr_reader :usage_log

      def merge_cost_currency(existing, incoming)
        return existing if missing?(incoming)
        return incoming if missing?(existing) || existing == incoming

        "mixed"
      end

      def merge_cost_source(existing, incoming)
        return existing if incoming == "none"
        return incoming if missing?(existing) || existing == "none" || existing == incoming

        "mixed"
      end

      def merge_numeric_details(existing, incoming)
        deep_sum(numeric_details(existing || {}), numeric_details(incoming || {}))
      end

      def numeric_details(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested_value), details|
            numeric_value = numeric_details(nested_value)
            details[key] = numeric_value unless missing_numeric_detail?(numeric_value)
          end
        when Numeric
          value
        end
      end

      def deep_sum(existing, incoming)
        incoming.each_with_object(existing.deep_dup) do |(key, incoming_value), details|
          existing_value = details[key]
          details[key] =
            if existing_value.is_a?(Hash) && incoming_value.is_a?(Hash)
              deep_sum(existing_value, incoming_value)
            elsif existing_value.is_a?(Numeric) && incoming_value.is_a?(Numeric)
              existing_value + incoming_value
            else
              incoming_value
            end
        end
      end

      def missing?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      def missing_numeric_detail?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end
    end
  end
end
