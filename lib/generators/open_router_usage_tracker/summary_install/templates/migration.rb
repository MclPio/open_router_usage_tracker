class CreateOpenRouterDailySummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :open_router_daily_summaries do |t|
      t.references :user, null: false, polymorphic: true
      t.date :day, null: false
      t.integer :total_tokens, null: false, default: 0
      t.decimal :cost, precision: 10, scale: 5, null: false, default: 0.0
      t.timestamps
    end

    add_index :open_router_daily_summaries, [ :user_type, :user_id, :day ], unique: true, name: "index_daily_summaries_on_user_and_day"
  end
end
