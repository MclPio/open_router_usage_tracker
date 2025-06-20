class CreateOpenRouterUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :open_router_usage_logs do |t|
      t.string :model, null: false
      t.integer :prompt_tokens, null: false
      t.integer :completion_tokens, null: false
      t.integer :total_tokens, null: false
      t.decimal :cost, precision: 10, scale: 5, null: false
      t.references :user, null: false, polymorphic: true
      t.string :request_id, null: false

      # Storing the raw API response is recommended for auditing and future-proofing.
      # If you are using PostgreSQL, you can change `t.json` to `t.jsonb` for
      # better performance and indexing capabilities.
      t.json :raw_usage_response, null: false, default: {}

      t.timestamps
    end

    add_index :open_router_usage_logs, :request_id, unique: true
  end
end
