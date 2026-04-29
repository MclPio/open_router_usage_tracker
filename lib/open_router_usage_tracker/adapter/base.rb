module OpenRouterUsageTracker
  require "open_router_usage_tracker/persistence/usage_recorder"

  module Adapter
    module Base
      SUPPORTED_PROVIDERS = OpenRouterUsageTracker::Providers.supported_provider_names

      # Logs an API usage event, creating a UsageLog and updating the DailySummary.
      # This is the primary method for recording usage data.
      #
      # @param response [Hash] The raw response hash from the API provider.
      # @param user [ApplicationRecord] The user object (e.g., User, Account) associated with the API call.
      # @param provider [String] The name of the API provider (e.g., 'open_router', 'open_ai').
      #   Defaults to 'open_router'.
      # @param store_raw_response [Boolean] If false, an empty hash will be stored in the
      #   raw_usage_response column. Defaults to true.
      # @param occurred_at [Time, DateTime, Date] When the provider request occurred.
      #   Defaults to Time.current.
      # @param on_duplicate [Symbol] Duplicate request behavior: :raise, :return_existing, or :ignore.
      #   Defaults to :raise.
      #
      # @return [OpenRouterUsageTracker::UsageLog, nil] The created usage log, existing usage log,
      #   or nil when on_duplicate is :ignore.
      #
      # @example Log a call and store the raw response
      #   OpenRouterUsageTracker.log(response: api_response, user: current_user)
      #
      # @example Log a call without storing the raw response
      #   OpenRouterUsageTracker.log(response: api_response, user: current_user, store_raw_response: false)
      #
      def log(response:, user:, provider: "open_router", store_raw_response: true, occurred_at: Time.current, on_duplicate: :raise)
        OpenRouterUsageTracker::Persistence::UsageRecorder.call(
          response: response,
          user: user,
          provider: provider,
          store_raw_response: store_raw_response,
          occurred_at: occurred_at,
          on_duplicate: on_duplicate
        )
      end
    end
  end
end
