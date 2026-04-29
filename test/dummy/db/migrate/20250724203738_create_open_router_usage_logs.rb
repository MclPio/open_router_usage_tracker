class CreateOpenRouterUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :open_router_usage_logs do |t|
      t.string :model, null: false
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.integer :cache_read_input_tokens, null: false, default: 0
      t.integer :cache_write_input_tokens, null: false, default: 0
      t.integer :reasoning_output_tokens, null: false, default: 0
      t.decimal :cost_amount, precision: 10, scale: 5, null: false, default: 0.0
      t.string :cost_currency
      t.string :cost_source, null: false, default: "none"
      t.references :user, null: false, polymorphic: true
      t.string :request_id, null: false
      t.string :provider, null: false, default: "open_router"
      t.datetime :occurred_at, null: false

      # Storing the raw API response is recommended for auditing and future-proofing.
      # If you are using PostgreSQL, you can change `t.json` to `t.jsonb` for
      # better performance and indexing capabilities.
      t.json :usage_details, null: false, default: {}
      t.json :raw_usage_response, null: false, default: {}

      t.timestamps
    end

    add_index :open_router_usage_logs, [ :provider, :request_id ], unique: true
    add_index :open_router_usage_logs, [ :user_type, :user_id, :occurred_at ], name: "index_usage_logs_on_user_and_occurred_at"
  end
end
