# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_26_161921) do
  create_table "open_router_daily_summaries", force: :cascade do |t|
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.date "day", null: false
    t.integer "input_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.integer "total_tokens", default: 0, null: false
    t.integer "cache_read_input_tokens", default: 0, null: false
    t.integer "cache_write_input_tokens", default: 0, null: false
    t.integer "reasoning_output_tokens", default: 0, null: false
    t.decimal "cost_amount", precision: 10, scale: 5, default: "0.0", null: false
    t.string "cost_currency"
    t.string "cost_source", default: "none", null: false
    t.json "usage_details", default: {}, null: false
    t.string "provider", default: "open_router", null: false
    t.string "model", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "user_type", "user_id", "day", "provider", "model" ], name: "index_daily_summaries_on_user_and_day_and_provider_and_model", unique: true
    t.index [ "user_type", "user_id" ], name: "index_open_router_daily_summaries_on_user"
  end

  create_table "open_router_usage_logs", force: :cascade do |t|
    t.string "model", null: false
    t.integer "input_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.integer "total_tokens", default: 0, null: false
    t.integer "cache_read_input_tokens", default: 0, null: false
    t.integer "cache_write_input_tokens", default: 0, null: false
    t.integer "reasoning_output_tokens", default: 0, null: false
    t.decimal "cost_amount", precision: 10, scale: 5, default: "0.0", null: false
    t.string "cost_currency"
    t.string "cost_source", default: "none", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.string "request_id", null: false
    t.string "provider", default: "open_router", null: false
    t.datetime "occurred_at", null: false
    t.json "usage_details", default: {}, null: false
    t.json "raw_usage_response", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "provider", "request_id" ], name: "index_open_router_usage_logs_on_provider_and_request_id", unique: true
    t.index [ "user_type", "user_id", "occurred_at" ], name: "index_usage_logs_on_user_and_occurred_at"
    t.index [ "user_type", "user_id" ], name: "index_open_router_usage_logs_on_user"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
