# test/open_router_usage_tracker_test.rb
require "test_helper"

class OpenRouterUsageTrackerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!
    @sample_response = { "id" => "or-12345", "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 } }

    # Store the original configuration before each test
    @original_configuration = OpenRouterUsageTracker.configuration.dup
  end

  teardown do
    # Restore the original configuration after each test to ensure isolation
    OpenRouterUsageTracker.configuration = @original_configuration
  end

  # ... your other tests are here ...

  # This is the new test case.
  test "log uses the custom user_foreign_key from configuration" do
    # 1. Change the configuration for this specific test
    OpenRouterUsageTracker.configure do |config|
      config.user_foreign_key = :human_id
    end

    # 2. Perform the action
    OpenRouterUsageTracker.log(response: @sample_response, user: @user)

    # 3. Assert the behavior
    log = OpenRouterUsageTracker::UsageLog.last
    assert_equal @user.id, log.human_id
    assert_nil log.user_id # Assert the default key was NOT used
  end
end
