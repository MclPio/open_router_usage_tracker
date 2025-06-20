require "test_helper"

module OpenRouterUsageTracker
  class UsageLogTest < ActiveSupport::TestCase
    setup do
      @user = User.create!
      @response = {
        "id" => "or-12345",
        "model" => "openai/gpt-4o",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 }
      }
    end

    # --- Test for a completely valid object ---
    test "is valid with all required attributes" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes)
      assert log.valid?, "Log should be valid with all attributes. Errors: #{log.errors.full_messages.join(", ")}"
    end

    # --- Tests for presence validations ---
    test "is invalid without a model" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:model))
      assert_not log.valid?
      assert_includes log.errors[:model], "can't be blank"
    end

    test "is invalid without prompt_tokens" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:prompt_tokens))
      assert_not log.valid?
      assert_includes log.errors[:prompt_tokens], "can't be blank"
    end

    test "is invalid without completion_tokens" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:completion_tokens))
      assert_not log.valid?
      assert_includes log.errors[:completion_tokens], "can't be blank"
    end

    test "is invalid without total_tokens" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:total_tokens))
      assert_not log.valid?
      assert_includes log.errors[:total_tokens], "can't be blank"
    end

    test "is invalid without a cost" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:cost))
      assert_not log.valid?
      assert_includes log.errors[:cost], "can't be blank"
    end

    test "is invalid without a raw_usage_response" do
        log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:raw_usage_response))
        assert_not log.valid?
        assert_includes log.errors[:raw_usage_response], "can't be blank"
    end

    test "is invalid without a request_id" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:request_id))
      assert_not log.valid?
      assert_includes log.errors[:request_id], "can't be blank"
    end

    test "is invalid without a user" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.except(:user))
      assert_not log.valid?
      assert_includes log.errors[:user], "must exist"
    end

    # --- Test for uniqueness validation ---
    test "is invalid with a duplicate request_id" do
      # Create the first valid log
      OpenRouterUsageTracker::UsageLog.create!(valid_attributes.merge(request_id: "duplicate-id"))

      # Attempt to create another with the same request_id
      duplicate_log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.merge(request_id: "duplicate-id"))

      assert_not duplicate_log.valid?
      assert_includes duplicate_log.errors[:request_id], "has already been taken"
    end

    private

    # Helper method to provide a hash of valid attributes.
    def valid_attributes
      {
        model: @response["model"],
        prompt_tokens: @response.dig("usage", "prompt_tokens"),
        completion_tokens: @response.dig("usage", "completion_tokens"),
        total_tokens: @response.dig("usage", "total_tokens"),
        cost: @response.dig("usage", "cost"),
        request_id: @response["id"],
        user: @user,
        raw_usage_response: @response
      }
    end
  end
end
