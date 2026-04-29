# OpenRouterUsageTracker

[![Build Status](https://github.com/mclpio/open_router_usage_tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/mclpio/open_router_usage_tracker/actions)
[![Gem Version](https://badge.fury.io/rb/open_router_usage_tracker.svg)](https://badge.fury.io/rb/open_router_usage_tracker)

`open_router_usage_tracker` is a Rails engine for recording user-scoped LLM usage. It normalizes provider responses into durable usage logs and daily summaries so Rails apps can audit requests, enforce limits, and build usage reports without spreading provider-specific accounting code through the app.

Supported providers:

- `open_router`
- `open_ai`
- `google`
- `anthropic`
- `x_ai`

## Install

Add the gem:

```ruby
gem "open_router_usage_tracker", "~> 2.0"
```

Generate and run the migrations:

```bash
bundle install
bin/rails g open_router_usage_tracker:install
bin/rails g open_router_usage_tracker:summary_install
bin/rails db:migrate
```

Add the concern to the model you want to bill or rate-limit:

```ruby
class User < ApplicationRecord
  include OpenRouterUsageTracker::Trackable
end
```

For existing v1 installs:

```bash
bin/rails g open_router_usage_tracker:upgrade_v2
bin/rails db:migrate
```

More setup detail: [Usage Guide](docs/usage.md).

## Log Usage

Call `OpenRouterUsageTracker.log` after a successful provider response:

```ruby
usage_log = OpenRouterUsageTracker.log(
  response: api_response,
  user: current_user,
  provider: "open_ai"
)
```

OpenRouter is the default provider:

```ruby
OpenRouterUsageTracker.log(response: open_router_response, user: current_user)
```

Useful options:

```ruby
OpenRouterUsageTracker.log(
  response: api_response,
  user: current_user,
  provider: "anthropic",
  store_raw_response: false,
  occurred_at: provider_timestamp,
  on_duplicate: :return_existing
)
```

Required provider response keys and duplicate behavior are covered in the [Usage Guide](docs/usage.md).

## Query Usage

The `Trackable` concern exposes daily summary and range helpers:

```ruby
summary = current_user.daily_usage_summary_for(
  day: Time.zone.today,
  provider: "open_router",
  model: "openai/gpt-4o"
)

if summary&.total_tokens.to_i > 100_000
  render json: { error: "Daily token limit exceeded" }, status: :too_many_requests
end
```

```ruby
last_30_days = 30.days.ago.to_date..Date.current

current_user.total_tokens_in_range(last_30_days, provider: "open_router")
current_user.total_cost_in_range(last_30_days, provider: "open_router")
current_user.request_count_in_range(last_30_days, provider: "open_router")
current_user.usage_totals_in_range(last_30_days, provider: "open_router")
```

## Configure Cost And Privacy

Provider-returned cost wins when present. For providers that do not return cost, configure exact provider/model pricing in your app:

```ruby
OpenRouterUsageTracker.configure do |config|
  config.pricing = {
    "open_ai" => {
      "gpt-4.1-2025-04-14" => {
        "input_cost_per_million" => 2.00,
        "output_cost_per_million" => 8.00,
        "currency" => "USD"
      }
    }
  }

  config.raw_response_redactor = lambda do |response|
    response.deep_dup.tap { |redacted| redacted.delete("api_key") }
  end
end
```

Cost precedence, cache/reasoning rates, and raw response retention are covered in the [Usage Guide](docs/usage.md).

## Documentation

- [Usage Guide](docs/usage.md): install, upgrade, logging, configuration, queries, and operations.
- [Architecture Guide](docs/architecture.md): how the Rails engine, parsers, persistence, models, and generators fit together.
- [Agent Operating Contract](docs/agent.md): contributor workflow for autonomous or AI-assisted work.
- [Project Pipeline](docs/pipeline.md): historical hardening plan and milestone record.
- [Release Guide](docs/release.md): supported matrix, version policy, and v2 release checklist.
- [Changelog](CHANGELOG.md): notable changes by release.

## Compatibility

The gem targets Rails 8.x on Ruby 3.2 and newer. CI covers Rails 8.0 and 8.1, Ruby 3.2 through 3.4, SQLite, and PostgreSQL.

## Contributing

Start with the [Architecture Guide](docs/architecture.md), then run:

```bash
bin/test
env RUBOCOP_CACHE_ROOT=/private/tmp/rubocop_cache bin/rubocop
```

Open an issue or PR with the behavior you want to change, the provider response shape involved, and the tests that prove the accounting stays correct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
