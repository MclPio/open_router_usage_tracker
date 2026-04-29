class CreateOpenRouterDailySummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :open_router_daily_summaries do |t|
      t.references :user, null: false, polymorphic: true
      t.date :day, null: false
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.integer :cache_read_input_tokens, null: false, default: 0
      t.integer :cache_write_input_tokens, null: false, default: 0
      t.integer :reasoning_output_tokens, null: false, default: 0
      t.decimal :cost_amount, precision: 10, scale: 5, null: false, default: 0.0
      t.string :cost_currency
      t.string :cost_source, null: false, default: "none"
      t.json :usage_details, null: false, default: {}
      t.string :provider, null: false, default: "open_router"
      t.string :model, null: false
      t.timestamps
    end

    add_index :open_router_daily_summaries, [ :user_type, :user_id, :day, :provider, :model ], unique: true, name: "index_daily_summaries_on_user_and_day_and_provider_and_model"
  end
end
