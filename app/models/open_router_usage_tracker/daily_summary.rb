module OpenRouterUsageTracker
  class DailySummary < ApplicationRecord
    self.table_name = "open_router_daily_summaries"

    belongs_to :user, polymorphic: true

    validates :day, presence: true
    validates :total_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
