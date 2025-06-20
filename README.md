# OpenRouterUsageTracker
[![Build Status](https://github.com/mclpio/open_router_usage_tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/mclpio/open_router_usage_tracker/actions)

An effortless Rails engine to track API token usage and cost from [OpenRouter](https://openrouter.ai/), enabling easy rate-limiting and monitoring for your users.

## Motivation
Managing Large Language Model (LLM) API costs is crucial for any application that provides AI features to users. This gem provides simple, out-of-the-box tools to log every OpenRouter API call, associate it with a user, and query their usage over time. This allows you to easily implement spending caps, rate limits, or usage-based billing tiers.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "open_router_usage_tracker"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install open_router_usage_tracker
```

## Setup

1. **Run the Install Generator**: This will create a migration file in your application to add the open_router_usage_logs table.
    ```bash
    bin/rails g open_router_usage_tracker:install
    ```

1. **Run the Database Migration**:
    ```bash
    bin/rails db:migrate
    ```

1. **Include the `Trackable` Concern**: To add the usage tracking methods (`usage_in_period`, etc.) to your user model, include the concern. This works with any user-like model (e.g., `User`, `Account`).
    ```ruby
    # app/models/user.rb
    class User < ApplicationRecord
      include OpenRouterUsageTracker::Trackable

      # ... rest of your model
    end
    ```

## Usage
Using the gem involves two parts: logging new requests and tracking existing usage.

### Logging a Request
In your application where you receive a successful response from the OpenRouter API, call the `log` method. It's designed to be simple and fail loudly if the data is invalid.

```ruby
# Assume `api_response` is the parsed JSON hash from OpenRouter
# and `current_user` is your authenticated user object.

begin
  OpenRouterUsageTracker.log(response: api_response, user: current_user)
rescue ActiveRecord::RecordInvalid => e
  # This can happen if the response hash is missing required keys
  # (e.g., 'id', 'model', 'usage').
  logger.error "Failed to log OpenRouter usage: #{e.message}"
end
```

### Tracking Usage
The `Trackable` concern adds powerful querying methods to your user model.

The main method is `usage_in_period(range)`, which returns a hash containing the total tokens and cost for a given time range.

**Example: Implementing a rate limit**

Imagine you want to prevent users from using more than 100,000 tokens in a 24-hour period.

```ruby
# somewhere in a controller or before_action

def check_usage_limit
  usage = current_user.usage_in_last_24_hours

  if usage[:tokens] > 100_000
    render json: { error: "You have exceeded your daily usage limit." }, status: :too_many_requests
    return
  end
end
```

The gem also provides `usage_in_last_24_hours` as a convenience method and you can always get all the data using `usage_logs`.

## Contributing
Open an issue first.

1. Fork the repository.
1. Create your feature branch (git checkout -b my-new-feature).
1. Commit your changes (git commit -am 'Add some feature').
1. Push to the branch (git push origin my-new-feature).
1. Create a new Pull Request.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
