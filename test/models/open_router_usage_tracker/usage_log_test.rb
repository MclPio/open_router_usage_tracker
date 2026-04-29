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

    # --- Tests for numericality validations ---
    test "is invalid with negative input_tokens" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.merge(input_tokens: -1))
      assert_not log.valid?
      assert_includes log.errors[:input_tokens], "must be greater than or equal to 0"
    end

    test "is invalid with negative output_tokens" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.merge(output_tokens: -1))
      assert_not log.valid?
      assert_includes log.errors[:output_tokens], "must be greater than or equal to 0"
    end

    test "is invalid with negative total_tokens" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.merge(total_tokens: -1))
      assert_not log.valid?
      assert_includes log.errors[:total_tokens], "must be greater than or equal to 0"
    end

    test "is invalid with negative cost_amount" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.merge(cost_amount: -0.001))
      assert_not log.valid?
      assert_includes log.errors[:cost_amount], "must be greater than or equal to 0"
    end

    test "is invalid with an unsupported cost_source" do
      log = OpenRouterUsageTracker::UsageLog.new(valid_attributes.merge(cost_source: "guessed"))
      assert_not log.valid?
      assert_includes log.errors[:cost_source], "is not included in the list"
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
        input_tokens: @response.dig("usage", "prompt_tokens"),
        output_tokens: @response.dig("usage", "completion_tokens"),
        total_tokens: @response.dig("usage", "total_tokens"),
        cache_read_input_tokens: 0,
        cache_write_input_tokens: 0,
        reasoning_output_tokens: 0,
        cost_amount: @response.dig("usage", "cost"),
        cost_source: "provider",
        cost_currency: "credits",
        request_id: @response["id"],
        user: @user,
        usage_details: {},
        occurred_at: Time.current,
        raw_usage_response: @response
      }
    end
  end
end
