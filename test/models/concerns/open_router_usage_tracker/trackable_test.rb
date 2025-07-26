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
    @user = User.create!
    @account = Account.create!

    # Define standard API responses with provider-specific token naming
    @open_ai_response = {
      "id" => "openai-1",
      "model" => "gpt-4o",
      "usage" => { "input_tokens" => 40, "output_tokens" => 60, "total_tokens" => 100, "cost" => 0.01 }
    }
    @open_router_response = {
      "id" => "openrouter-1",
      "model" => "anthropic/claude-3.5-sonnet",
      "usage" => { "prompt_tokens" => 80, "completion_tokens" => 120, "total_tokens" => 200, "cost" => 0.02 }
    }

    # Use the .log method to create a realistic test data setup
    OpenRouterUsageTracker.log(response: @open_ai_response, user: @user, provider: "open_ai")
    OpenRouterUsageTracker.log(response: @open_router_response, user: @user, provider: "open_router")

    # Create a unique response for the second OpenAI log to avoid request_id collision
    account_open_ai_response = @open_ai_response.deep_dup
    account_open_ai_response["id"] = "openai-2"
    OpenRouterUsageTracker.log(response: account_open_ai_response, user: @account, provider: "open_ai")
  end

  # --- Core Functionality Tests ---

  test "#daily_usage_summary_for returns the correct summary" do
    summary = @user.daily_usage_summary_for(day: @today, provider: "open_ai", model: "gpt-4o")
    assert_not_nil summary
    assert_equal 100, summary.total_tokens
    assert_equal 40, summary.prompt_tokens
    assert_equal 60, summary.completion_tokens
    assert_equal "gpt-4o", summary.model
  end

  test "#daily_usage_summary_for returns nil for a non-existent provider" do
    summary = @user.daily_usage_summary_for(day: @today, provider: "google", model: "gemini-1.5-pro")
    assert_nil summary
  end

  test "#daily_usage_summary_for returns nil for a non-existent model" do
    summary = @user.daily_usage_summary_for(day: @today, provider: "open_ai", model: "gpt-4-turbo")
    assert_nil summary
  end

  # --- Polymorphism Tests ---

  test "works with a polymorphic user model (Account)" do
    summary = @account.daily_usage_summary_for(day: @today, provider: "open_ai", model: "gpt-4o")
    assert_not_nil summary
    assert_equal 100, summary.total_tokens
  end

  # --- Data Retention Policy Tests ---

  test "deleting a user (by default) does NOT delete their usage data" do
    user_to_delete = User.create!
    log_response = { "id" => "test-1", "model" => "test", "usage" => { "prompt_tokens" => 10, "completion_tokens" => 10, "total_tokens" => 20, "cost" => 0 } }
    OpenRouterUsageTracker.log(response: log_response, user: user_to_delete, provider: "open_router")

    assert_no_difference [ "OpenRouterUsageTracker::UsageLog.count", "OpenRouterUsageTracker::DailySummary.count" ] do
      user_to_delete.destroy
    end
  end

  test "deleting a user with dependent: :destroy deletes their usage data" do
    user_to_delete = UserWithDeletion.create!
    log_response = { "id" => "test-2", "model" => "test", "usage" => { "prompt_tokens" => 10, "completion_tokens" => 10, "total_tokens" => 20, "cost" => 0 } }
    OpenRouterUsageTracker.log(response: log_response, user: user_to_delete, provider: "open_router")

    assert_difference "OpenRouterUsageTracker::UsageLog.count", -1 do
      assert_difference "OpenRouterUsageTracker::DailySummary.count", -1 do
        user_to_delete.destroy
      end
    end
  end
end
