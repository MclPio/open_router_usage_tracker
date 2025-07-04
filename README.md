# OpenRouterUsageTracker
[![Build Status](https://github.com/mclpio/open_router_usage_tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/mclpio/open_router_usage_tracker/actions)
[![Gem Version](https://badge.fury.io/rb/open_router_usage_tracker.svg)](https://badge.fury.io/rb/open_router_usage_tracker)

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
bundle
```

Or install it yourself as:
```bash
gem install open_router_usage_tracker
```

## Setup

1. **Run the Install Generator**: This will create a migration file in your application to add the `open_router_usage_logs` table.
    ```bash
    bin/rails g open_router_usage_tracker:install
    ```

2. **Run the Summary Table Generator (New in v0.2.0)**: To enable performant daily rate-limiting, generate the migration for the summary table.
    ```bash
    bin/rails g open_router_usage_tracker:summary_install
    ```

3. **Run the Database Migrations**:
    ```bash
    bin/rails db:migrate
    ```

4. **Include the `Trackable` Concern**: To add the usage tracking methods (`usage_in_period`, etc.) to your user model, include the concern. This works with any user-like model (e.g., `User`, `Account`).
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

### Daily Usage Tracking and Rate-Limiting (Recommended)

For high-performance rate-limiting, the gem provides helpers that query a daily summary table. This avoids slow `SUM` queries on the main log table.

The primary method is `cost_exceeded?(limit:)`, which provides a near-instantaneous check against a user's daily spending.

**Example: Implementing a daily cost limit**

Imagine you want to prevent users from spending more than $1.00 per day.

```ruby
# somewhere in a controller or before_action

def enforce_daily_limit
  # This check is extremely fast as it queries the small summary table.
  if current_user.cost_exceeded?(limit: 1.00)
    render json: { error: "You have exceeded your daily spending limit." }, status: :too_many_requests
    return
  end
end
```

You can also retrieve the full summary for the current day (UTC):

```ruby
summary = current_user.usage_today
# => <OpenRouterUsageTracker::DailySummary id: 1, user_id: 1, day: "2025-06-28", total_tokens: 1500, cost: 0.025, ...>

summary.cost
# => 0.025

summary.total_tokens
# => 1500
```

### Historical Usage Tracking

The `Trackable` concern also adds methods for querying historical usage from the main log table.

The main method is `usage_in_period(range)`, which returns a hash containing the total tokens and cost for a given time range.

**Example: Checking usage for the current month**

```ruby
range = Time.current.beginning_of_month..Time.current
usage = current_user.usage_in_period(range)
# => { tokens: 50000, cost: 1.25 }
```

**DEPRECATED for rate-limiting**: The `usage_in_last_24_hours` method is still available but is **not recommended** for implementing rate limits due to its performance implications. Use `cost_exceeded?` instead for a more robust and scalable solution.

## Contributing
Open an issue first.

1. Fork the repository.
1. Create your feature branch (git checkout -b my-new-feature).
1. Commit your changes (git commit -am 'Add some feature').
1. Push to the branch (git push origin my-new-feature).
1. Create a new Pull Request.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
