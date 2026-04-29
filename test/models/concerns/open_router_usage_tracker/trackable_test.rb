require "test_helper"

# Define dummy models for testing polymorphism and data retention policies
class Account < ApplicationRecord
  self.table_name = "users"
  include OpenRouterUsageTracker::Trackable
end

class UserWithDeletion < ApplicationRecord
  self.table_name = "users"
  include OpenRouterUsageTracker::Trackable
  has_many :usage_logs, as: :user, class_name: "OpenRouterUsageTracker::UsageLog", dependent: :destroy
  has_many :daily_summaries, as: :user, class_name: "OpenRouterUsageTracker::DailySummary", dependent: :destroy
end

class TrackableConcernTest < ActiveSupport::TestCase
  setup do
    @today = Date.current
    @yesterday = @today - 1.day
    @user = User.create!
    @account = Account.create!

    # --- Test Data Setup ---
    # Use a variety of providers, models, and dates to ensure robust testing.

    # Today's logs for @user
    log_response(@user, provider: "open_router", model: "ornl/claude-3.5-sonnet", cost: 0.02, request_id: "user-or-1")
    log_response(@user, provider: "open_router", model: "google/gemini-flash-1.5", cost: 0.03, request_id: "user-or-2")
    log_response(@user, provider: "open_ai", model: "gpt-4o", cost: 0, request_id: "user-oa-1") # No cost from OpenAI

    # Yesterday's logs for @user
    travel_to @yesterday do
      log_response(@user, provider: "open_router", model: "ornl/claude-3.5-sonnet", cost: 0.04, request_id: "user-or-3")
      log_response(@user, provider: "google", model: "gemini-pro-1.5", cost: 0, request_id: "user-gg-1")
    end

    # Today's logs for @account
    log_response(@account, provider: "open_router", model: "ornl/claude-3.5-sonnet", cost: 0.05, request_id: "acct-or-1")
  end

  # --- #daily_usage_summary_for Tests ---

  test "#daily_usage_summary_for returns the correct summary" do
    summary = @user.daily_usage_summary_for(day: @today, provider: "open_router", model: "ornl/claude-3.5-sonnet")
    assert_not_nil summary
    assert_equal 0.02, summary.cost_amount
  end

  test "#daily_usage_summary_for returns nil for a non-existent provider" do
    summary = @user.daily_usage_summary_for(day: @today, provider: "anthropic", model: "claude-3-opus")
    assert_nil summary
  end

  test "#daily_usage_summary_for returns nil for a non-existent model for a given provider" do
    summary = @user.daily_usage_summary_for(day: @today, provider: "open_ai", model: "gpt-4-turbo")
    assert_nil summary
  end

  # --- #total_cost_in_range Tests ---

  test "#total_cost_in_range calculates cost for a specific model in a date range" do
    range = @yesterday..@today
    cost = @user.total_cost_in_range(range, provider: "open_router", model: "ornl/claude-3.5-sonnet")
    assert_equal 0.06, cost # 0.02 (today) + 0.04 (yesterday)
  end

  test "#total_cost_in_range calculates cost for all models from a provider in a date range" do
    range = @yesterday..@today
    cost = @user.total_cost_in_range(range, provider: "open_router")
    assert_equal 0.09, cost # 0.02 + 0.03 (today) + 0.04 (yesterday)
  end

  test "#total_cost_in_range returns zero for a provider with no cost data" do
    range = @yesterday..@today
    cost = @user.total_cost_in_range(range, provider: "open_ai")
    assert_equal 0, cost
  end

  test "#total_cost_in_range returns zero for a date range with no usage" do
    range = (@today + 1.day)..(@today + 2.days)
    cost = @user.total_cost_in_range(range, provider: "open_router")
    assert_equal 0, cost
  end

  test "#total_cost_in_range correctly scopes by user" do
    range = @yesterday..@today
    account_cost = @account.total_cost_in_range(range, provider: "open_router")
    assert_equal 0.05, account_cost
  end

  test "#total_tokens_in_range calculates tokens for a provider" do
    range = @yesterday..@today
    tokens = @user.total_tokens_in_range(range, provider: "open_router")
    assert_equal 60, tokens
  end

  test "#request_count_in_range counts usage logs by occurred_at" do
    range = @yesterday..@today
    request_count = @user.request_count_in_range(range, provider: "open_router")
    assert_equal 3, request_count
  end

  test "#request_count_in_range preserves precise time ranges" do
    user = User.create!
    early_time = Time.zone.local(2026, 4, 1, 8, 0, 0)
    late_time = Time.zone.local(2026, 4, 1, 20, 0, 0)

    log_response(user, model: "time-window/model", request_id: "time-window-early", occurred_at: early_time)
    log_response(user, model: "time-window/model", request_id: "time-window-late", occurred_at: late_time)

    request_count = user.request_count_in_range(
      Time.zone.local(2026, 4, 1, 19, 0, 0)..Time.zone.local(2026, 4, 1, 21, 0, 0),
      provider: "open_router",
      model: "time-window/model"
    )

    assert_equal 1, request_count
  end

  test "#request_count_in_range expands plain date ranges to full days" do
    user = User.create!
    early_time = Time.zone.local(2026, 4, 1, 8, 0, 0)
    late_time = Time.zone.local(2026, 4, 1, 20, 0, 0)

    log_response(user, model: "date-window/model", request_id: "date-window-early", occurred_at: early_time)
    log_response(user, model: "date-window/model", request_id: "date-window-late", occurred_at: late_time)

    request_count = user.request_count_in_range(
      Date.new(2026, 4, 1)..Date.new(2026, 4, 1),
      provider: "open_router",
      model: "date-window/model"
    )

    assert_equal 2, request_count
  end

  test "#usage_totals_in_range returns token and cost totals" do
    range = @yesterday..@today
    totals = @user.usage_totals_in_range(range, provider: "open_router")

    assert_equal 30, totals[:input_tokens]
    assert_equal 30, totals[:output_tokens]
    assert_equal 60, totals[:total_tokens]
    assert_equal 0.09, totals[:cost_amount]
  end

  # --- Polymorphism Tests ---

  test "works with a polymorphic user model (Account)" do
    summary = @account.daily_usage_summary_for(day: @today, provider: "open_router", model: "ornl/claude-3.5-sonnet")
    assert_not_nil summary
    assert_equal 0.05, summary.cost_amount
  end

  # --- Data Retention Policy Tests ---

  test "deleting a user (by default) does NOT delete their usage data" do
    user_to_delete = User.create!
    log_response(user_to_delete, request_id: "del-1")

    assert_no_difference [ "OpenRouterUsageTracker::UsageLog.count", "OpenRouterUsageTracker::DailySummary.count" ] do
      user_to_delete.destroy
    end
  end

  test "deleting a user with dependent: :destroy deletes their usage data" do
    user_to_delete = UserWithDeletion.create!
    log_response(user_to_delete, request_id: "del-2")

    assert_difference "OpenRouterUsageTracker::UsageLog.count", -1 do
      assert_difference "OpenRouterUsageTracker::DailySummary.count", -1 do
        user_to_delete.destroy
      end
    end
  end

  private

  # Helper to create a standard log entry, reducing test boilerplate.
  def log_response(user, provider: "open_router", model: "test/model", cost: 0.0, request_id: SecureRandom.uuid, occurred_at: Time.current)
    response =
      if provider == "google"
        {
          "model" => model,
          "responseId" => request_id,
          "usageMetadata" => {
            "promptTokenCount" => 10,
            "candidatesTokenCount" => 10,
            "totalTokenCount" => 20
          },
          "usage" => { "cost" => cost }
        }
      else
        {
          "id" => request_id,
          "model" => model,
          "usage" => { "prompt_tokens" => 10, "completion_tokens" => 10, "total_tokens" => 20, "cost" => cost }
        }
      end

    OpenRouterUsageTracker.log(response: response, user: user, provider: provider, occurred_at: occurred_at)
  end
end
