require "test_helper"

module OpenRouterUsageTracker
  class UsageLogTest < ActiveSupport::TestCase
    setup do
      @user = User.create!
    end

    test "is valid with all required attributes" do
      log = OpenRouterUsageTracker::UsageLog.new(
        model: "openai/gpt-4o",
        prompt_tokens: 10,
        completion_tokens: 20,
        total_tokens: 30,
        cost: 0.001,
        request_id: "unique-request-1",
        user: @user
      )
      assert log.valid?, "Log should be valid with all required attributes"
    end

    test "is invalid without a request_id" do
      log = OpenRouterUsageTracker::UsageLog.new(request_id: nil, user: @user)
      assert_not log.valid?
      assert_includes log.errors[:request_id], "can't be blank"
    end

    test "is invalid with a duplicate request_id" do
      OpenRouterUsageTracker::UsageLog.create!(
        model: "test", prompt_tokens: 1, completion_tokens: 1, total_tokens: 2, cost: 0,
        request_id: "duplicate-id",
        user: @user
      )

      # Attempt to create a second log with the same request_id.
      duplicate_log = OpenRouterUsageTracker::UsageLog.new(request_id: "duplicate-id", user: @user)
      assert_not duplicate_log.valid?
      assert_includes duplicate_log.errors[:request_id], "has already been taken"
    end

    test "is invalid without a user" do
      log = OpenRouterUsageTracker::UsageLog.new(user: nil)
      assert_not log.valid?
      assert_includes log.errors[:user], "must exist"
    end

    # You can add similar "is invalid without..." tests for other attributes
    # like `model`, `cost`, etc. to be fully comprehensive.
  end
end