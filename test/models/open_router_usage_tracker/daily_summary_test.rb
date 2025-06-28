require "test_helper"

module OpenRouterUsageTracker
  class DailySummaryTest < ActiveSupport::TestCase
    setup do
      @user = User.create!
      @today = Date.current
    end

    test ".log creates a daily summary record if one does not exist" do
      api_response = {
        "id" => "gen-1", "model" => "test/model",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.01 }
      }

      assert_difference("DailySummary.count", 1) do
        OpenRouterUsageTracker.log(response: api_response, user: @user)
      end

      summary = @user.daily_summaries.find_by(day: @today)
      assert_not_nil summary
      assert_equal 30, summary.total_tokens
      assert_equal 0.01, summary.cost
    end

    test ".log updates an existing daily summary record" do
      summary = DailySummary.create!(user: @user, day: @today, total_tokens: 50, cost: 0.05)

      api_response = {
        "id" => "gen-2", "model" => "test/model",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.01 }
      }

      assert_no_difference("DailySummary.count") do
        OpenRouterUsageTracker.log(response: api_response, user: @user)
      end

      summary.reload
      assert_equal 80, summary.total_tokens # 50 + 30
      assert_equal 0.06, summary.cost     # 0.05 + 0.01
    end

    test ".log handles multiple concurrent requests correctly" do
      api_response_1 = { "id" => "gen-3", "model" => "test/model", "usage" => { "prompt_tokens" => 5, "completion_tokens" => 5, "total_tokens" => 10, "cost" => 0.01 } }
      api_response_2 = { "id" => "gen-4", "model" => "test/model", "usage" => { "prompt_tokens" => 7, "completion_tokens" => 8, "total_tokens" => 15, "cost" => 0.02 } }

      # Simulate concurrent logging
      threads = []
      threads << Thread.new { OpenRouterUsageTracker.log(response: api_response_1, user: @user) }
      threads << Thread.new { OpenRouterUsageTracker.log(response: api_response_2, user: @user) }
      threads.each(&:join)

      summary = @user.daily_summaries.find_by(day: @today)
      assert_not_nil summary
      assert_equal 25, summary.total_tokens
      assert_equal 0.03, summary.cost
      assert_equal 1, @user.daily_summaries.count
    end
  end
end
