require "test_helper"

class TrackableTest < ActiveSupport::TestCase
  setup do
    @user = User.create!
    @today = Date.current
  end

  test "#usage_today returns the correct summary for today" do
    summary = OpenRouterUsageTracker::DailySummary.create!(user: @user, day: @today, total_tokens: 100, cost: 0.1)
    assert_equal summary, @user.usage_today
  end

  test "#usage_today returns nil if no usage today" do
    assert_nil @user.usage_today
  end

  test "#cost_exceeded? returns true if the daily cost limit is exceeded" do
    OpenRouterUsageTracker::DailySummary.create!(user: @user, day: @today, cost: 1.5)
    assert @user.cost_exceeded?(limit: 1.0)
  end

  test "#cost_exceeded? returns false if the daily cost limit is not exceeded" do
    OpenRouterUsageTracker::DailySummary.create!(user: @user, day: @today, cost: 0.5)
    assert_not @user.cost_exceeded?(limit: 1.0)
  end

  test "#cost_exceeded? returns false if there is no usage for the day" do
    assert_not @user.cost_exceeded?(limit: 1.0)
  end
end
