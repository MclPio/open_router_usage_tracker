require "test_helper"

class MaintenanceTest < ActiveSupport::TestCase
  setup do
    @previous_configuration = OpenRouterUsageTracker.configuration
    OpenRouterUsageTracker.configuration = OpenRouterUsageTracker::Configuration.new
    @user = User.create!
  end

  teardown do
    OpenRouterUsageTracker.configuration = @previous_configuration
  end

  test "raw response redactor runs before persistence" do
    OpenRouterUsageTracker.configuration.raw_response_redactor = lambda do |response|
      response.deep_dup.tap { |redacted| redacted["api_key"] = "[FILTERED]" }
    end
    response = open_router_response("redacted-raw")
    response["api_key"] = "secret-key"

    usage_log = OpenRouterUsageTracker.log(response: response, user: @user)

    assert_equal "[FILTERED]", usage_log.raw_usage_response["api_key"]
    assert_equal "secret-key", response["api_key"]
  end

  test "log emits active support notification" do
    events = []
    callback = lambda do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    ActiveSupport::Notifications.subscribed(callback, "log.open_router_usage_tracker") do
      OpenRouterUsageTracker.log(response: open_router_response("instrumented-log"), user: @user)
    end

    assert_equal 1, events.size
    payload = events.first.payload
    assert_equal "open_router", payload[:provider]
    assert_equal "openai/gpt-4o", payload[:model]
    assert_equal "instrumented-log", payload[:request_id]
    assert_equal "User", payload[:user_type]
    assert_equal @user.id, payload[:user_id]
  end

  test "daily summary rebuilder recreates summaries from usage logs" do
    OpenRouterUsageTracker.log(response: open_router_response("rebuild-1"), user: @user)
    OpenRouterUsageTracker.log(response: open_router_response("rebuild-2"), user: @user)
    OpenRouterUsageTracker::DailySummary.delete_all

    rebuilt_count = OpenRouterUsageTracker::Maintenance::DailySummaryRebuilder.call

    assert_equal 2, rebuilt_count
    summary = @user.daily_usage_summary_for(day: Date.current, provider: "open_router", model: "openai/gpt-4o")
    assert_equal 60, summary.total_tokens
    assert_equal 0.002, summary.cost_amount
  end

  test "daily summary rebuilder removes stale summaries during a full rebuild" do
    stale_summary = OpenRouterUsageTracker::DailySummary.create!(
      user: @user,
      day: Date.current,
      provider: "open_router",
      model: "stale/model",
      input_tokens: 1,
      output_tokens: 1,
      total_tokens: 999,
      cache_read_input_tokens: 0,
      cache_write_input_tokens: 0,
      reasoning_output_tokens: 0,
      cost_amount: 0,
      cost_source: "none",
      usage_details: {}
    )
    OpenRouterUsageTracker.log(response: open_router_response("rebuild-kept"), user: @user)

    rebuilt_count = OpenRouterUsageTracker::Maintenance::DailySummaryRebuilder.call

    assert_equal 1, rebuilt_count
    assert_nil OpenRouterUsageTracker::DailySummary.find_by(id: stale_summary.id)
    rebuilt_summary = @user.daily_usage_summary_for(day: Date.current, provider: "open_router", model: "openai/gpt-4o")
    assert_equal 30, rebuilt_summary.total_tokens
  end

  test "daily summary rebuilder only replaces summaries for scoped logs" do
    other_user = User.create!
    OpenRouterUsageTracker.log(response: open_router_response("rebuild-scoped"), user: @user)
    OpenRouterUsageTracker.log(response: open_router_response("rebuild-unscoped"), user: other_user)
    OpenRouterUsageTracker::DailySummary.update_all(total_tokens: 999)

    rebuilt_count = OpenRouterUsageTracker::Maintenance::DailySummaryRebuilder.call(
      scope: OpenRouterUsageTracker::UsageLog.where(user: @user)
    )

    assert_equal 1, rebuilt_count
    scoped_summary = @user.daily_usage_summary_for(day: Date.current, provider: "open_router", model: "openai/gpt-4o")
    untouched_summary = other_user.daily_usage_summary_for(day: Date.current, provider: "open_router", model: "openai/gpt-4o")
    assert_equal 30, scoped_summary.total_tokens
    assert_equal 999, untouched_summary.total_tokens
  end

  test "raw response pruner removes only old raw responses" do
    old_log = OpenRouterUsageTracker.log(
      response: open_router_response("old-raw"),
      user: @user,
      occurred_at: 2.days.ago
    )
    recent_log = OpenRouterUsageTracker.log(
      response: open_router_response("recent-raw"),
      user: @user,
      occurred_at: Time.current
    )

    pruned_count = OpenRouterUsageTracker::Maintenance::RawResponsePruner.call(before: 1.day.ago)

    assert_equal 1, pruned_count
    assert_equal({}, old_log.reload.raw_usage_response)
    assert_not_equal({}, recent_log.reload.raw_usage_response)
  end

  private

  def open_router_response(request_id)
    {
      "id" => request_id,
      "model" => "openai/gpt-4o",
      "usage" => {
        "prompt_tokens" => 10,
        "completion_tokens" => 20,
        "total_tokens" => 30,
        "cost" => 0.001
      }
    }
  end
end
