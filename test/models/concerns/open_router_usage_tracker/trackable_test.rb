require "test_helper"

class TrackableDummy < ApplicationRecord
  self.table_name = "users"
  include OpenRouterUsageTracker::Trackable
end

class TrackableTest < ActiveSupport::TestCase
  setup do
    # Create a user that we can attach logs to.
    @user = TrackableDummy.create!

    # Create a series of usage logs at different points in time.
    # We use `travel_to` to precisely control the `created_at` timestamp.

    # Log created 2 days ago
    travel_to 2.days.ago do
      OpenRouterUsageTracker::UsageLog.create!(user: @user, model: "test-model", request_id: "old-1", prompt_tokens: 50, completion_tokens: 50, total_tokens: 100, cost: 0.01, raw_usage_response: { "id" => 12 })
    end

    # Log created 12 hours ago
    travel_to 12.hours.ago do
      OpenRouterUsageTracker::UsageLog.create!(user: @user, model: "test-model", request_id: "recent-1", prompt_tokens: 100, completion_tokens: 150, total_tokens: 250, cost: 0.05, raw_usage_response: { "id" => 13 })
    end

    # Log created 2 hours ago
    travel_to 2.hours.ago do
      OpenRouterUsageTracker::UsageLog.create!(user: @user, model: "test-model", request_id: "recent-2", prompt_tokens: 200, completion_tokens: 200, total_tokens: 400, cost: 0.10, raw_usage_response: { "id" => 14 })
    end
  end

  test "usage_in_period correctly sums tokens and cost for a specific range" do
    # We'll check the period from 1 day ago to now.
    # This should only include the logs created 12 and 2 hours ago.
    # Expected tokens: 250 + 400 = 650
    # Expected cost: 0.05 + 0.10 = 0.15
    range = 24.hours.ago..Time.current
    usage = @user.usage_in_period(range)

    assert_equal 650, usage[:tokens]
    assert_equal 0.15, usage[:cost]
  end

  test "usage_in_period returns zero when no logs are in the range" do
    # Check a time period in the future where no logs exist.
    range = 1.hour.from_now..2.hours.from_now
    usage = @user.usage_in_period(range)

    assert_equal 0, usage[:tokens]
    assert_equal 0, usage[:cost]
  end

  test "usage_in_last_24_hours convenience method works correctly" do
    # This method should yield the same result as our first test.
    # Expected tokens: 250 + 400 = 650
    # Expected cost: 0.05 + 0.10 = 0.15
    usage = @user.usage_in_last_24_hours

    assert_equal 650, usage[:tokens]
    assert_equal 0.15, usage[:cost]
  end

  test "returns zero for a user with no usage logs" do
    new_user = TrackableDummy.create!
    usage = new_user.usage_in_last_24_hours

    assert_equal 0, usage[:tokens]
    assert_equal 0, usage[:cost]
  end

  test "has_many association works and can retrieve logs" do
    assert_equal 3, @user.usage_logs.count
    assert @user.usage_logs.all? { |log| log.is_a?(OpenRouterUsageTracker::UsageLog) }
  end
end
