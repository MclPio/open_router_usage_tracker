require "test_helper"

module OpenRouterUsageTracker
  class DailySummaryTest < ActiveSupport::TestCase
    setup do
      @user = User.create!
      @today = Date.current

      @open_ai_response = {
        "id" => "resp_67ccd2bed1ec8190b14f964abc0542670bb6a6b452d3795b",
        "model" => "gpt-4.1-2025-04-14",
        "usage" => {
          "input_tokens" => 36,
          "input_tokens_details" => {
            "cached_tokens" => 0
          },
          "output_tokens" => 87,
          "output_tokens_details" => {
            "reasoning_tokens" => 0
          },
          "total_tokens" => 123
        }
      }

      @open_router_response = {
        "id" => "or-12345",
        "model" => "openai/gpt-4o",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 }
      }
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
      summary = DailySummary.create!(user: @user, day: @today, total_tokens: 50, cost: 0.05, model: "super-cool")

      api_response = {
        "id" => "gen-2", "model" => "super-cool",
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

    test "saves prompt and completion tokens" do
      api_response = {
        "id" => "gen-1", "model" => "test/model",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.01 }
      }

      assert_difference("DailySummary.count", 1) do
        OpenRouterUsageTracker.log(response: api_response, user: @user)
      end

      summary = @user.daily_summaries.find_by(day: @today)
      assert_not_nil summary
      assert_equal 10, summary.prompt_tokens
      assert_equal 20, summary.completion_tokens
    end

    test "can save and update 2 different providers on same day" do
      assert_difference "DailySummary.count", 2 do
        OpenRouterUsageTracker.log(response: @open_ai_response, user: @user, provider: "open_ai")
        OpenRouterUsageTracker.log(response: @open_router_response, user: @user, provider: "open_router")
      end
    end

    test "can save same provider different model" do
      modified_open_ai_response = @open_ai_response.deep_dup
      modified_open_ai_response["model"] = "super-gpt"
      modified_open_ai_response["id"] = "wahoo"

      assert_difference "DailySummary.count", 2 do
        OpenRouterUsageTracker.log(response: @open_ai_response, user: @user, provider: "open_ai")
        OpenRouterUsageTracker.log(response: modified_open_ai_response, user: @user, provider: "open_ai")
      end
    end

    test "fetching daily summary presents different provider/model combinations for the day" do
      OpenRouterUsageTracker.log(response: @open_ai_response, user: @user, provider: "open_ai")
      OpenRouterUsageTracker.log(response: @open_router_response, user: @user, provider: "open_router")

      open_ai_summary = @user.daily_summaries.find_by(day: @today, provider: "open_ai")
      open_router_summary = @user.daily_summaries.find_by(day: @today, provider: "open_router")

      assert_equal @open_ai_response["model"], open_ai_summary["model"]
      assert_equal @open_ai_response.dig("usage", "total_tokens"), open_ai_summary["total_tokens"]

      assert_equal @open_router_response["model"], open_router_summary["model"]
      assert_equal @open_router_response.dig("usage", "total_tokens"), open_router_summary["total_tokens"]
    end
  end
end
