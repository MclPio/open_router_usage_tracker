# test/open_router_usage_tracker_test.rb
require "test_helper"

class OpenRouterUsageTrackerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!
    @sample_response = {
        "id" => "or-12345",
        "model" => "openai/gpt-4o",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 }
      }
    @openai_response = {
      "id" => "resp_67ccd2bed1ec8190b14f964abc0542670bb6a6b452d3795b",
      "object" => "response",
      "created_at" => 1741476542,
      "status" => "completed",
      "error" => nil,
      "incomplete_details" => nil,
      "instructions" => nil,
      "max_output_tokens" => nil,
      "model" => "gpt-4.1-2025-04-14",
      "output" => [
        {
          "type" => "message",
          "id" => "msg_67ccd2bf17f0819081ff3bb2cf6508e60bb6a6b452d3795b",
          "status" => "completed",
          "role" => "assistant",
          "content" => [
            {
              "type" => "output_text",
              "text" => "In a peaceful grove beneath a silver moon, a unicorn named Lumina discovered a hidden pool that reflected the stars. As she dipped her horn into the water, the pool began to shimmer, revealing a pathway to a magical realm of endless night skies. Filled with wonder, Lumina whispered a wish for all who dream to find their own hidden magic, and as she glanced back, her hoofprints sparkled like stardust.",
              "annotations" => []
            }
          ]
        }
      ],
      "parallel_tool_calls" => true,
      "previous_response_id" => nil,
      "reasoning" => {
        "effort" => nil,
        "summary" => nil
      },
      "store" => true,
      "temperature" => 1.0,
      "text" => {
        "format" => {
          "type" => "text"
        }
      },
      "tool_choice" => "auto",
      "tools" => [],
      "top_p" => 1.0,
      "truncation" => "disabled",
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
      },
      "user" => nil,
      "metadata" => {}
    }
  end

  test "log creates a new usage log record" do
    assert_difference "OpenRouterUsageTracker::UsageLog.count", 1 do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user)
    end

    log = OpenRouterUsageTracker::UsageLog.last
    assert_equal @user, log.user
    assert_equal "openai/gpt-4o", log.model
    assert_equal 30, log.total_tokens
  end

  test "accepts provider name" do
    assert_nothing_raised do
      OpenRouterUsageTracker.log(response: @sample_response, user: @user, provider: :openai)
    end
  end

  test "openai response with provier is saved to the database" do
    usage_log = OpenRouterUsageTracker.log(response: @openai_response, user: @user, provider: :openai)
  end

  # test "identifies openai response and routes it correctly" do
  # end

  # test "identifies anthropic response and routes it correctly" do
  # end

  # test "identifies xAI response and routes it correctly" do
  # end
end
