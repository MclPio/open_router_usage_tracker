class CreateOpenRouterUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :open_router_usage_logs do |t|
      t.string :model, null: false
      t.integer :prompt_tokens, null: false
      t.integer :completion_tokens, null: false
      t.integer :total_tokens, null: false
      t.decimal :cost, precision: 10, scale: 5, null: false
      t.references :user, polymorphic: true, null: false
      t.string :request_id, null: false
      t.json :raw_usage_response, null: false, default: {}

      t.timestamps
    end

    add_index :open_router_usage_logs, :request_id, unique: true
  end
end
