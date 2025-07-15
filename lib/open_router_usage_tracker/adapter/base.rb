module OpenRouterUsageTracker
  require "open_router_usage_tracker/parsers/open_ai"
  require "open_router_usage_tracker/parsers/open_router"
  module Adapter
    module Base
      SUPPORTED_PROVIDERS = [ "open_ai", "open_router", "google", "anthropic" ].freeze

      def log(response:, user:, provider: "open_router")
        unless SUPPORTED_PROVIDERS.include?(provider)
          raise ArgumentError.new("Unsupported provider: #{provider}. Supported providers are: #{SUPPORTED_PROVIDERS.join(', ')}")
        end

        parser_class = "OpenRouterUsageTracker::Parsers::#{provider.camelize}".constantize
        attributes = parser_class.parse(response)
        attributes[:user] = user

        ApplicationRecord.transaction do
          usage_log = OpenRouterUsageTracker::UsageLog.create!(attributes)
          update_daily_summary(usage_log)
          usage_log
        end
      end

      private

      # def create_usage_log(response, user)
      #   attributes = {
      #     model: response["model"],
      #     prompt_tokens: response.dig("usage", "prompt_tokens"),
      #     completion_tokens: response.dig("usage", "completion_tokens"),
      #     total_tokens: response.dig("usage", "total_tokens"),
      #     cost: response.dig("usage", "cost"),
      #     request_id: response["id"],
      #     raw_usage_response: response,
      #     user: user
      #   }
      #   # print(attributes)
      #   # {:model=>"openai/gpt-4o", :prompt_tokens=>10, :completion_tokens=>20, :total_tokens=>30, :cost=>0.001, :request_id=>"or-12345", :raw_usage_response=>{"id"=>"or-12345", "model"=>"openai/gpt-4o", "usage"=>{"prompt_tokens"=>10, "completion_tokens"=>20, "total_tokens"=>30, "cost"=>0.001}}, :user=>#<User id: 1, created_at: "2025-07-15 17:29:20.739781000 +0000", updated_at: "2025-07-15 17:29:20.739781000 +0000">}
      #   OpenRouterUsageTracker::UsageLog.create!(attributes)
      # end

      def update_daily_summary(usage_log)
        summary = OpenRouterUsageTracker::DailySummary.find_or_initialize_by(
          user: usage_log.user,
          day: Date.current
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
