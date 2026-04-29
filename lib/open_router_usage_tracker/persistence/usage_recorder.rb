require "open_router_usage_tracker/providers/registry"
require "open_router_usage_tracker/persistence/daily_summary_updater"
require "open_router_usage_tracker/cost_calculator"
require "active_support/notifications"

module OpenRouterUsageTracker
  module Persistence
    class UsageRecorder
      DUPLICATE_POLICIES = [ :raise, :return_existing, :ignore ].freeze

      def self.call(response:, user:, provider:, store_raw_response:, occurred_at:, on_duplicate:)
        new(
          response: response,
          user: user,
          provider: provider,
          store_raw_response: store_raw_response,
          occurred_at: occurred_at,
          on_duplicate: on_duplicate
        ).call
      end

      def initialize(response:, user:, provider:, store_raw_response:, occurred_at:, on_duplicate:)
        @response = response
        @user = user
        @provider = provider
        @store_raw_response = store_raw_response
        @occurred_at = occurred_at
        @on_duplicate = on_duplicate.to_sym
      end

      def call
        validate_duplicate_policy!
        usage = parsed_usage
        attributes = usage.to_log_attributes
        attributes[:user] = user
        attributes[:raw_usage_response] = store_raw_response ? redacted_raw_response : {}
        attributes[:provider] = provider
        attributes[:occurred_at] = normalized_occurred_at

        if on_duplicate != :raise
          existing_usage_log = duplicate_usage_log(attributes[:request_id])
          return duplicate_result(existing_usage_log) if existing_usage_log
        end

        instrument_log(usage) do
          ApplicationRecord.transaction do
            usage_log = OpenRouterUsageTracker::UsageLog.create!(attributes)
            OpenRouterUsageTracker::Persistence::DailySummaryUpdater.call(usage_log)
            usage_log
          end
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        existing_usage_log = duplicate_usage_log(attributes[:request_id])
        return duplicate_result(existing_usage_log) if existing_usage_log && on_duplicate != :raise

        raise
      end

      private

      attr_reader :response, :user, :provider, :store_raw_response, :occurred_at, :on_duplicate

      def parsed_usage
        usage = OpenRouterUsageTracker::Providers.parser_for(provider).parse(response)
        OpenRouterUsageTracker::CostCalculator.call(usage, provider: provider)
      end

      def redacted_raw_response
        OpenRouterUsageTracker.configuration.redact_raw_response(response)
      end

      def normalized_occurred_at
        occurred_at.respond_to?(:in_time_zone) ? occurred_at.in_time_zone : occurred_at
      end

      def duplicate_usage_log(request_id)
        OpenRouterUsageTracker::UsageLog.find_by(provider: provider, request_id: request_id)
      end

      def duplicate_result(existing_usage_log)
        return existing_usage_log if on_duplicate == :return_existing
        return nil if on_duplicate == :ignore

        raise ArgumentError, "Unsupported duplicate policy: #{on_duplicate}"
      end

      def validate_duplicate_policy!
        return if DUPLICATE_POLICIES.include?(on_duplicate)

        raise ArgumentError, "Unsupported duplicate policy: #{on_duplicate}. Supported policies are: #{DUPLICATE_POLICIES.join(', ')}"
      end

      def instrument_log(usage, &block)
        ActiveSupport::Notifications.instrument(
          "log.open_router_usage_tracker",
          provider: provider,
          model: usage.model,
          request_id: usage.request_id,
          user_type: user.class.name,
          user_id: user.id
        ) do
          block.call
        end
      end
    end
  end
end
