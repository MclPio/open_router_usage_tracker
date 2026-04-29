class UpgradeOpenRouterUsageTrackerToV2 < ActiveRecord::Migration[8.0]
  def up
    upgrade_usage_logs
    upgrade_daily_summaries
  end

  def down
    downgrade_daily_summaries
    downgrade_usage_logs
  end

  private

  def upgrade_usage_logs
    rename_column :open_router_usage_logs, :prompt_tokens, :input_tokens if column_exists?(:open_router_usage_logs, :prompt_tokens)
    rename_column :open_router_usage_logs, :completion_tokens, :output_tokens if column_exists?(:open_router_usage_logs, :completion_tokens)
    rename_column :open_router_usage_logs, :cost, :cost_amount if column_exists?(:open_router_usage_logs, :cost)

    add_column :open_router_usage_logs, :cache_read_input_tokens, :integer, null: false, default: 0 unless column_exists?(:open_router_usage_logs, :cache_read_input_tokens)
    add_column :open_router_usage_logs, :cache_write_input_tokens, :integer, null: false, default: 0 unless column_exists?(:open_router_usage_logs, :cache_write_input_tokens)
    add_column :open_router_usage_logs, :reasoning_output_tokens, :integer, null: false, default: 0 unless column_exists?(:open_router_usage_logs, :reasoning_output_tokens)
    add_column :open_router_usage_logs, :cost_currency, :string unless column_exists?(:open_router_usage_logs, :cost_currency)
    add_column :open_router_usage_logs, :cost_source, :string, null: false, default: "none" unless column_exists?(:open_router_usage_logs, :cost_source)
    add_column :open_router_usage_logs, :usage_details, :json, null: false, default: {} unless column_exists?(:open_router_usage_logs, :usage_details)
    add_column :open_router_usage_logs, :occurred_at, :datetime unless column_exists?(:open_router_usage_logs, :occurred_at)

    execute "UPDATE open_router_usage_logs SET occurred_at = created_at WHERE occurred_at IS NULL"
    execute <<~SQL
      UPDATE open_router_usage_logs
      SET cost_source = CASE
        WHEN provider = 'open_router' AND cost_amount > 0 THEN 'provider'
        WHEN cost_amount > 0 THEN 'manual_response'
        ELSE 'none'
      END
      WHERE cost_source IS NULL OR cost_source = 'none'
    SQL
    execute "UPDATE open_router_usage_logs SET cost_currency = 'credits' WHERE provider = 'open_router' AND cost_amount > 0 AND cost_currency IS NULL"

    change_column_null :open_router_usage_logs, :occurred_at, false
    add_index :open_router_usage_logs, [ :user_type, :user_id, :occurred_at ], name: "index_usage_logs_on_user_and_occurred_at" unless index_exists?(:open_router_usage_logs, [ :user_type, :user_id, :occurred_at ], name: "index_usage_logs_on_user_and_occurred_at")
  end

  def upgrade_daily_summaries
    rename_column :open_router_daily_summaries, :prompt_tokens, :input_tokens if column_exists?(:open_router_daily_summaries, :prompt_tokens)
    rename_column :open_router_daily_summaries, :completion_tokens, :output_tokens if column_exists?(:open_router_daily_summaries, :completion_tokens)
    rename_column :open_router_daily_summaries, :cost, :cost_amount if column_exists?(:open_router_daily_summaries, :cost)

    add_column :open_router_daily_summaries, :cache_read_input_tokens, :integer, null: false, default: 0 unless column_exists?(:open_router_daily_summaries, :cache_read_input_tokens)
    add_column :open_router_daily_summaries, :cache_write_input_tokens, :integer, null: false, default: 0 unless column_exists?(:open_router_daily_summaries, :cache_write_input_tokens)
    add_column :open_router_daily_summaries, :reasoning_output_tokens, :integer, null: false, default: 0 unless column_exists?(:open_router_daily_summaries, :reasoning_output_tokens)
    add_column :open_router_daily_summaries, :cost_currency, :string unless column_exists?(:open_router_daily_summaries, :cost_currency)
    add_column :open_router_daily_summaries, :cost_source, :string, null: false, default: "none" unless column_exists?(:open_router_daily_summaries, :cost_source)
    add_column :open_router_daily_summaries, :usage_details, :json, null: false, default: {} unless column_exists?(:open_router_daily_summaries, :usage_details)

    execute <<~SQL
      UPDATE open_router_daily_summaries
      SET cost_source = CASE
        WHEN provider = 'open_router' AND cost_amount > 0 THEN 'provider'
        WHEN cost_amount > 0 THEN 'manual_response'
        ELSE 'none'
      END
      WHERE cost_source IS NULL OR cost_source = 'none'
    SQL
    execute "UPDATE open_router_daily_summaries SET cost_currency = 'credits' WHERE provider = 'open_router' AND cost_amount > 0 AND cost_currency IS NULL"
  end

  def downgrade_usage_logs
    remove_index :open_router_usage_logs, name: "index_usage_logs_on_user_and_occurred_at" if index_exists?(:open_router_usage_logs, [ :user_type, :user_id, :occurred_at ], name: "index_usage_logs_on_user_and_occurred_at")
    remove_column :open_router_usage_logs, :occurred_at if column_exists?(:open_router_usage_logs, :occurred_at)
    remove_column :open_router_usage_logs, :usage_details if column_exists?(:open_router_usage_logs, :usage_details)
    remove_column :open_router_usage_logs, :cost_source if column_exists?(:open_router_usage_logs, :cost_source)
    remove_column :open_router_usage_logs, :cost_currency if column_exists?(:open_router_usage_logs, :cost_currency)
    remove_column :open_router_usage_logs, :reasoning_output_tokens if column_exists?(:open_router_usage_logs, :reasoning_output_tokens)
    remove_column :open_router_usage_logs, :cache_write_input_tokens if column_exists?(:open_router_usage_logs, :cache_write_input_tokens)
    remove_column :open_router_usage_logs, :cache_read_input_tokens if column_exists?(:open_router_usage_logs, :cache_read_input_tokens)

    rename_column :open_router_usage_logs, :cost_amount, :cost if column_exists?(:open_router_usage_logs, :cost_amount)
    rename_column :open_router_usage_logs, :output_tokens, :completion_tokens if column_exists?(:open_router_usage_logs, :output_tokens)
    rename_column :open_router_usage_logs, :input_tokens, :prompt_tokens if column_exists?(:open_router_usage_logs, :input_tokens)
  end

  def downgrade_daily_summaries
    remove_column :open_router_daily_summaries, :usage_details if column_exists?(:open_router_daily_summaries, :usage_details)
    remove_column :open_router_daily_summaries, :cost_source if column_exists?(:open_router_daily_summaries, :cost_source)
    remove_column :open_router_daily_summaries, :cost_currency if column_exists?(:open_router_daily_summaries, :cost_currency)
    remove_column :open_router_daily_summaries, :reasoning_output_tokens if column_exists?(:open_router_daily_summaries, :reasoning_output_tokens)
    remove_column :open_router_daily_summaries, :cache_write_input_tokens if column_exists?(:open_router_daily_summaries, :cache_write_input_tokens)
    remove_column :open_router_daily_summaries, :cache_read_input_tokens if column_exists?(:open_router_daily_summaries, :cache_read_input_tokens)

    rename_column :open_router_daily_summaries, :cost_amount, :cost if column_exists?(:open_router_daily_summaries, :cost_amount)
    rename_column :open_router_daily_summaries, :output_tokens, :completion_tokens if column_exists?(:open_router_daily_summaries, :output_tokens)
    rename_column :open_router_daily_summaries, :input_tokens, :prompt_tokens if column_exists?(:open_router_daily_summaries, :input_tokens)
  end
end
