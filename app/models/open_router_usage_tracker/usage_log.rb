module OpenRouterUsageTracker
  # This class represents a single entry of an OpenRouter API call.
  class UsageLog < ApplicationRecord
    self.table_name = "open_router_usage_logs"
    COST_SOURCES = [ "provider", "manual_response", "configured_pricing", "none" ].freeze

    belongs_to :user, polymorphic: true

    validates :model, presence: true
    validates :input_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :output_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :total_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :cache_read_input_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :cache_write_input_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :reasoning_output_tokens, numericality: { greater_than_or_equal_to: 0 }
    validates :cost_amount, numericality: { greater_than_or_equal_to: 0 }
    validates :cost_source, inclusion: { in: COST_SOURCES }
    validates :provider, presence: true
    validates :usage_details, exclusion: { in: [ nil ] }
    validates :occurred_at, presence: true
    validates :request_id, presence: true, uniqueness: { scope: :provider }
  end
end
