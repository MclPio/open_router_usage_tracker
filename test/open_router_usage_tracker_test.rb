require "test_helper"

class OpenRouterUsageTrackerTest < ActiveSupport::TestCase
  setup do
    # Create a dummy user from your dummy app's User model
    @user = User.create!
    # Define a sample successful OpenRouter response hash
    @sample_response = { "id" => "or-12345", "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 } }
  end

  # --- Test the Logging Logic ---

  test "log creates a UsageLog record with correct attributes" do
    assert_difference "OpenRouterUsageTracker::UsageLog.count", 1 do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user)
    end

    log = OpenRouterUsageTracker::UsageLog.last
    assert_equal 10, log.prompt_tokens
    assert_equal 20, log.completion_tokens
    assert_equal 0.001, log.cost
    assert_equal @user, log.user # Assumes default `user_id` foreign key
    assert_equal "or-12345", log.request_id
  end

  test "log does not create a record if request_id is a duplicate" do
    OpenRouterUsageTracker.log(response: @sample_response, user: @user) # First time

    # Assert that running it a second time does NOT create a new record
    assert_no_difference "OpenRouterUsageTracker::UsageLog.count" do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user)
    end
  end

  test "log works with a custom configured user_foreign_key" do
    # You will need to change the configuration for this specific test
    # and have a dummy model with a different foreign key, e.g., 'human_id'.
  end

  # --- Test the Reporting Logic ---

  test "usage_for_period returns correct token count" do
    # Create a few log entries for @user
    OpenRouterUsageTracker.log(response: @sample_response.deep_merge({ "id" => "a" }), user: @user) # 30 tokens
    OpenRouterUsageTracker.log(response: @sample_response.deep_merge({ "id" => "b" }), user: @user) # 30 tokens

    # Create an old log entry that should be outside the window
    old_log = OpenRouterUsageTracker.log(response: @sample_response.deep_merge({ "id" => "c" }), user: @user)
    old_log.update_column(:created_at, 2.days.ago)

    # Assert that the usage in the last 24 hours is 60 tokens
    assert_equal 60, OpenRouterUsageTracker.usage_for_period(user: @user, duration: 24.hours)
  end
end
