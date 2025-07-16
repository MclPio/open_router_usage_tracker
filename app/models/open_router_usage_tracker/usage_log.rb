module OpenRouterUsageTracker
  # This class represents a single entry of an OpenRouter API call.
  class UsageLog < ApplicationRecord
    self.table_name = "open_router_usage_logs"

    belongs_to :user, polymorphic: true

    validates :model, presence: true
    validates :prompt_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :completion_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :total_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :cost, numericality: { greater_than_or_equal_to: 0 }

    validates :request_id, presence: true, uniqueness: true
  end
end
