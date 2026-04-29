module OpenRouterUsageTracker
  class DailySummary < ApplicationRecord
    self.table_name = "open_router_daily_summaries"
    COST_SOURCES = [ "provider", "manual_response", "configured_pricing", "none", "mixed" ].freeze

    belongs_to :user, polymorphic: true

    validates :day, presence: true
    validates :total_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :input_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :output_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cache_read_input_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cache_write_input_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :reasoning_output_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cost_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :cost_source, inclusion: { in: COST_SOURCES }
    validates :usage_details, exclusion: { in: [ nil ] }
    validates :model, presence: true
    validates :provider, presence: true
  end
end
