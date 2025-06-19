OpenRouterUsageTracker.configure do |config|
  # This specifies the column name in your `usage_logs` table that references
  # the user. You can change it to :human_id, :account_id, etc.
  # The associated column in `open_router_usage_logs` should be named accordingly
  # (e.g., `human_id` and `human_id_type` for a polymorphic association).
  config.user_foreign_key = :user_id
end
