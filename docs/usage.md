# Usage Guide

This guide is for Rails application developers integrating `open_router_usage_tracker`.

For full Rails app examples, initializer placement, service object patterns, and accepted argument types, see [Integration Examples](integration_examples.md).

## Install

```ruby
gem "open_router_usage_tracker", "~> 2.0"
```

```bash
bundle install
bin/rails g open_router_usage_tracker:install
bin/rails g open_router_usage_tracker:summary_install
bin/rails db:migrate
```

Add the concern to the user-like model that owns usage:

```ruby
class User < ApplicationRecord
  include OpenRouterUsageTracker::Trackable
end
```

The concern does not set `dependent:` on associations. Choose your own retention policy:

```ruby
class User < ApplicationRecord
  include OpenRouterUsageTracker::Trackable

  has_many :usage_logs, as: :user, class_name: "OpenRouterUsageTracker::UsageLog", dependent: :destroy
  has_many :daily_summaries, as: :user, class_name: "OpenRouterUsageTracker::DailySummary", dependent: :destroy
end
```

## Upgrade From v1

Version 2 uses input/output token naming, cost metadata, `usage_details`, and `occurred_at`.

```bash
bin/rails g open_router_usage_tracker:upgrade_v2
bin/rails db:migrate
```

The upgrade generator renames `prompt_tokens` to `input_tokens`, `completion_tokens` to `output_tokens`, and `cost` to `cost_amount`. It also adds cache/reasoning counters, `cost_currency`, `cost_source`, `usage_details`, and `occurred_at`.

After upgrading, rebuild summaries if you need historical aggregates to reflect repaired or richer accounting data:

```bash
bin/rails open_router_usage_tracker:summaries:rebuild
```

## Log A Provider Response

Call `OpenRouterUsageTracker.log` after a successful provider response. The response should be a parsed hash.

```ruby
OpenRouterUsageTracker.log(response: open_router_response, user: current_user)
OpenRouterUsageTracker.log(response: openai_response, user: current_user, provider: "open_ai")
OpenRouterUsageTracker.log(response: google_response, user: current_user, provider: "google")
```

Supported providers:

- `open_router`
- `open_ai`
- `google`
- `anthropic`
- `x_ai`

### Logging Options

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

- `provider`: defaults to `open_router`.
- `store_raw_response`: defaults to `true`; set to `false` to persist `{}` in `raw_usage_response`.
- `occurred_at`: defaults to `Time.current`; controls the usage log timestamp and summary day.
- `on_duplicate`: defaults to `:raise`; use `:return_existing` or `:ignore` for idempotent callers.

## Required Provider Keys

The gem needs a model, a provider request id, and a usage object. Missing or invalid required fields raise `OpenRouterUsageTracker::ParseError` before anything is persisted.

- OpenRouter, OpenAI, Anthropic, and xAI request id: `id`
- Google request id: `responseId`
- OpenRouter, OpenAI, Anthropic, and xAI usage object: `usage`
- Google usage object: `usageMetadata`

Provider notes:

- OpenAI supports Responses API usage fields (`input_tokens`, `output_tokens`) and Chat Completions fields (`prompt_tokens`, `completion_tokens`).
- xAI supports Chat Completions and Responses-style usage fields.
- Anthropic cache creation/read tokens are counted as input-side tokens.
- Google cache and thoughts tokens are preserved in normalized details and core counters where possible.

## Cost Behavior

Cost precedence is:

1. Provider-returned cost, currently authoritative for OpenRouter.
2. Manual `usage.cost` supplied in non-OpenRouter responses.
3. Configured exact provider/model pricing.
4. No cost, stored as `0` with `cost_source = "none"`.

Manual response cost:

```ruby
openai_response["usage"]["cost"] = calculated_cost
OpenRouterUsageTracker.log(response: openai_response, user: current_user, provider: "open_ai")
```

Configured pricing:

```ruby
OpenRouterUsageTracker.configure do |config|
  config.pricing = {
    "open_ai" => {
      "gpt-4.1-2025-04-14" => {
        "input_cost_per_million" => 2.00,
        "output_cost_per_million" => 8.00,
        "cache_read_input_cost_per_million" => 0.50,
        "cache_write_input_cost_per_million" => 2.50,
        "reasoning_output_cost_per_million" => 8.00,
        "currency" => "USD"
      }
    }
  }
end
```

The gem does not fetch live provider prices. Keep pricing in your app config and update it when your billing policy changes.

## Privacy And Raw Responses

Raw responses are stored by default for audits and parser regressions. Configure redaction before persistence:

```ruby
OpenRouterUsageTracker.configure do |config|
  config.raw_response_redactor = lambda do |response|
    response.deep_dup.tap do |redacted|
      redacted.delete("api_key")
      redacted["metadata"]&.delete("email")
    end
  end
end
```

You can also disable raw response storage per call:

```ruby
OpenRouterUsageTracker.log(response: api_response, user: current_user, store_raw_response: false)
```

`usage_details` remains available even when raw response storage is disabled.

## Query Usage

Daily summary lookup:

```ruby
summary = current_user.daily_usage_summary_for(
  day: Time.zone.today,
  provider: "open_router",
  model: "openai/gpt-4o"
)
```

Range helpers:

```ruby
range = 30.days.ago.to_date..Date.current

current_user.total_cost_in_range(range, provider: "open_router")
current_user.total_tokens_in_range(range, provider: "open_router")
current_user.request_count_in_range(range, provider: "open_router")
current_user.usage_totals_in_range(range, provider: "open_router")
```

For request counts, `Date` ranges expand to full days. `Time` ranges remain exact.

## Operations

Rebuild summaries:

```bash
bin/rails open_router_usage_tracker:summaries:rebuild
```

Prune old raw responses while keeping normalized usage and summaries:

```bash
bin/rails open_router_usage_tracker:raw_responses:prune BEFORE=2026-01-01
```

Subscribe to logging instrumentation:

```ruby
ActiveSupport::Notifications.subscribe("log.open_router_usage_tracker") do |_name, _started, _finished, _id, payload|
  Rails.logger.info(payload.slice(:provider, :model, :request_id, :user_type, :user_id))
end
```

For PostgreSQL applications, consider changing generated `json` columns to `jsonb` if you need JSON indexing or heavier reporting on `usage_details`.
