module OpenRouterUsageTracker
  require "open_router_usage_tracker/parsers/open_ai"
  require "open_router_usage_tracker/parsers/open_router"
  module Adapter
    module Base
      SUPPORTED_PROVIDERS = [ "open_ai", "open_router", "google", "anthropic" ].freeze

      # Logs an API usage event, creating a UsageLog and updating the DailySummary.
      # This is the primary method for recording usage data.
      #
      # @param response [Hash] The raw response hash from the API provider.
      # @param user [ApplicationRecord] The user object (e.g., User, Account) associated with the API call.
      # @param provider [String] The name of the API provider (e.g., 'open_router', 'open_ai').
      #   Defaults to 'open_router'.
      # @param store_raw_response [Boolean] If false, an empty hash will be stored in the
      #   raw_usage_response column. Defaults to true.
      #
      # @return [OpenRouterUsageTracker::UsageLog] The newly created usage log record.
      #
      # @example Log a call and store the raw response
      #   OpenRouterUsageTracker.log(response: api_response, user: current_user)
      #
      # @example Log a call without storing the raw response
      #   OpenRouterUsageTracker.log(response: api_response, user: current_user, store_raw_response: false)
      #
      def log(response:, user:, provider: "open_router", store_raw_response: true)
        unless SUPPORTED_PROVIDERS.include?(provider)
          raise ArgumentError.new("Unsupported provider: #{provider}. Supported providers are: #{SUPPORTED_PROVIDERS.join(', ')}")
        end

        parser_class = "OpenRouterUsageTracker::Parsers::#{provider.camelize}".constantize
        attributes = parser_class.parse(response)
        attributes[:user] = user
        attributes[:raw_usage_response] = {} unless store_raw_response
        attributes[:provider] = provider

        ApplicationRecord.transaction do
          usage_log = OpenRouterUsageTracker::UsageLog.create!(attributes)
          update_daily_summary(usage_log)
          usage_log
        end
      end

      private

      def update_daily_summary(usage_log)
        summary = OpenRouterUsageTracker::DailySummary.find_or_initialize_by(
          user: usage_log.user,
          day: Date.current,
          provider: usage_log.provider,
          model: usage_log.model
        )
        summary.total_tokens += usage_log.total_tokens
        summary.cost += usage_log.cost
        summary.prompt_tokens += usage_log.prompt_tokens
        summary.completion_tokens += usage_log.completion_tokens
        summary.save!
      end
    end
  end
end
