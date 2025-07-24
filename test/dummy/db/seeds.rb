# basic seeds for testing in rails console.

user = User.create!

response = {
        "id" => "or-12345",
        "model" => "openai/gpt-4o",
        "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30, "cost" => 0.001 }
      }

usage_log = OpenRouterUsageTracker.log(response: response, user: user)
