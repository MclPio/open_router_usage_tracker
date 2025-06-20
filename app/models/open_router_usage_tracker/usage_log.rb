module OpenRouterUsageTracker
  # This class represents a single entry of an OpenRouter API call.
  class UsageLog < ApplicationRecord
    self.table_name = "open_router_usage_logs"

    belongs_to :user, polymorphic: true

    validates :model, presence: true
    validates :prompt_tokens, presence: true
    validates :completion_tokens, presence: true
    validates :total_tokens, presence: true
    validates :cost, presence: true
    validates :raw_usage_response, presence: true

    validates :request_id, presence: true, uniqueness: true
  end
end
