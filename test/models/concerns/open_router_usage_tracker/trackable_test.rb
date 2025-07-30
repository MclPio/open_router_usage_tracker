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
    assert_equal 0.02, summary.cost
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

  # --- Polymorphism Tests ---

  test "works with a polymorphic user model (Account)" do
    summary = @account.daily_usage_summary_for(day: @today, provider: "open_router", model: "ornl/claude-3.5-sonnet")
    assert_not_nil summary
    assert_equal 0.05, summary.cost
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
  def log_response(user, provider: "open_router", model: "test/model", cost: 0.0, request_id: SecureRandom.uuid)
    response = {
      "model" => model,
      "usage" => { "prompt_tokens" => 10, "completion_tokens" => 10, "total_tokens" => 20, "cost" => cost }
    }

    if provider == "google"
      response["responseId"] = request_id
    else
      response["id"] = request_id
    end

    OpenRouterUsageTracker.log(response: response, user: user, provider: provider)
  end
end
