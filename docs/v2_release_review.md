# v2 Release Review Checklist

Use this guide before publishing v2. It is written for a careful maintainer reading the repository and then testing the gem as a real Rails user.

## 1. Start With The Release Story

Read these files first:

1. `README.md`: confirms the short user-facing promise and install path.
2. `CHANGELOG.md`: confirms the release notes explain breaking and notable changes.
3. `docs/usage.md`: confirms host-app setup and operations are understandable.
4. `docs/integration_examples.md`: confirms real integration examples match the public API.
5. `docs/architecture.md`: confirms implementation structure matches the code.
6. `docs/release.md`: confirms version policy, supported matrix, and release checklist.

Questions to answer:

- Can a Rails developer install and log their first request from the README alone?
- Can a maintainer understand where parsing, persistence, summaries, and generators live?
- Are v2 breaking changes obvious enough before a user runs migrations?

## 2. Review Public API And Configuration

Inspect:

- `lib/open_router_usage_tracker.rb`
- `lib/open_router_usage_tracker/adapter/base.rb`
- `lib/open_router_usage_tracker/configuration.rb`
- `app/models/concerns/open_router_usage_tracker/trackable.rb`

Check:

- `OpenRouterUsageTracker.log` arguments match README and docs.
- `OpenRouterUsageTracker.configure` supports pricing and raw response redaction.
- Supported providers are documented exactly as registered.
- Query helpers have clear provider/model scoping.
- `Date` and `Time` range behavior is covered in docs and tests.

Manual console checks in the repo:

```bash
bin/test test/models/concerns/open_router_usage_tracker/trackable_test.rb
bin/test test/cost_calculator_test.rb
```

## 3. Review Provider Parsing

Inspect:

- `lib/open_router_usage_tracker/providers/registry.rb`
- `lib/open_router_usage_tracker/providers/base_parser.rb`
- `lib/open_router_usage_tracker/providers/*/parser.rb`
- `lib/open_router_usage_tracker/normalized_usage.rb`
- `test/fixtures/provider_responses/`
- `test/providers/provider_parser_contract_test.rb`

Check:

- Every parser returns `OpenRouterUsageTracker::NormalizedUsage`.
- Required missing fields raise `OpenRouterUsageTracker::ParseError`.
- String and symbol keyed responses work where supported.
- Cache, reasoning, total token, cost, and detail fields map intentionally.
- Provider fixture field names still match current provider docs.

Manual commands:

```bash
bin/test test/providers/provider_parser_contract_test.rb
bin/test test/providers/registry_test.rb
```

## 4. Review Persistence And Accounting

Inspect:

- `lib/open_router_usage_tracker/persistence/usage_recorder.rb`
- `lib/open_router_usage_tracker/persistence/daily_summary_updater.rb`
- `app/models/open_router_usage_tracker/usage_log.rb`
- `app/models/open_router_usage_tracker/daily_summary.rb`
- `test/open_router_usage_tracker_test.rb`
- `test/models/open_router_usage_tracker/*_test.rb`

Check:

- Usage log creation and daily summary update happen in one transaction.
- Duplicate request policies do not double-count summaries.
- `provider + request_id` uniqueness is enforced.
- Summary day uses `occurred_at`.
- Cost source/currency merging is intentional.
- Raw response redaction happens before persistence.
- `usage_details` persists even when raw response storage is disabled.

Manual commands:

```bash
bin/test test/open_router_usage_tracker_test.rb
bin/test test/models/open_router_usage_tracker/usage_log_test.rb
bin/test test/models/open_router_usage_tracker/daily_summary_test.rb
bin/test test/maintenance_test.rb
```

## 5. Review Migrations And Generators

Inspect:

- `lib/generators/open_router_usage_tracker/install/templates/migration.rb`
- `lib/generators/open_router_usage_tracker/summary_install/templates/migration.rb`
- `lib/generators/open_router_usage_tracker/upgrade_v2/templates/migration.rb`
- `test/dummy/db/schema.rb`
- `test/generators/install_generator_test.rb`

Check:

- Fresh install schema matches the models.
- Upgrade migration handles v1 column names.
- Upgrade migration classifies historical OpenRouter costs as `provider` and non-OpenRouter positive costs as `manual_response`.
- Generator timestamps do not collide when generators run together.
- PostgreSQL users can reasonably switch generated `json` columns to `jsonb` if needed.

Manual command:

```bash
bin/test test/generators/install_generator_test.rb
```

## 6. Test The Gem In A Fresh Dummy App

Create a disposable Rails app outside the repository:

```bash
cd /private/tmp
rm -rf ourt_review_app
rails new ourt_review_app --skip-javascript --skip-hotwire --skip-action-mailbox --skip-action-text
cd ourt_review_app
```

Point the app at the local gem:

```ruby
# Gemfile
gem "open_router_usage_tracker", path: "/Users/mclpio/repos/open_router_usage_tracker"
```

Install and generate migrations:

```bash
bundle install
bin/rails g model User
bin/rails g open_router_usage_tracker:install
bin/rails g open_router_usage_tracker:summary_install
bin/rails db:migrate
```

Configure the user model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include OpenRouterUsageTracker::Trackable
end
```

Create an initializer:

```ruby
# config/initializers/open_router_usage_tracker.rb
OpenRouterUsageTracker.configure do |config|
  config.pricing = {
    "open_ai" => {
      "gpt-test" => {
        "input_cost_per_million" => 1.00,
        "output_cost_per_million" => 2.00,
        "currency" => "USD"
      }
    }
  }

  config.raw_response_redactor = ->(response) { response.deep_dup.except("api_key") }
end
```

Run console checks:

```bash
bin/rails console
```

```ruby
user = User.create!

open_router_response = {
  "id" => "or-review-1",
  "model" => "openai/gpt-4o",
  "api_key" => "secret",
  "usage" => {
    "prompt_tokens" => 10,
    "completion_tokens" => 20,
    "total_tokens" => 30,
    "cost" => 0.001
  }
}

log = OpenRouterUsageTracker.log(response: open_router_response, user: user)
log.total_tokens
log.cost_source
log.raw_usage_response.key?("api_key")

summary = user.daily_usage_summary_for(day: Time.zone.today, provider: "open_router", model: "openai/gpt-4o")
summary.total_tokens
summary.cost_amount

duplicate = OpenRouterUsageTracker.log(response: open_router_response, user: user, on_duplicate: :return_existing)
duplicate.id == log.id

OpenRouterUsageTracker.log(
  response: {
    "id" => "openai-review-1",
    "model" => "gpt-test",
    "usage" => { "input_tokens" => 1_000, "output_tokens" => 2_000, "total_tokens" => 3_000 }
  },
  user: user,
  provider: "open_ai"
).cost_source

user.usage_totals_in_range(Time.zone.today..Time.zone.today, provider: "open_router")
```

Expected:

- OpenRouter log persists with `cost_source == "provider"`.
- Raw response is redacted by the initializer.
- Daily summary totals increase once, not twice after duplicate logging.
- OpenAI configured pricing produces `cost_source == "configured_pricing"`.
- Query helpers return totals without custom SQL.

Test maintenance tasks in the dummy app:

```bash
bin/rails open_router_usage_tracker:summaries:rebuild
bin/rails open_router_usage_tracker:raw_responses:prune BEFORE=2099-01-01
```

Expected:

- Summary rebuild completes and keeps summary totals consistent with logs.
- Raw response pruning clears old raw responses without deleting logs or summaries.

## 7. Test v1 Upgrade In A Disposable App

Use another disposable app or reset the dummy app database. Create v1-like tables manually or by checking out the previous release, then run:

```bash
bin/rails g open_router_usage_tracker:upgrade_v2
bin/rails db:migrate
```

Check:

- `prompt_tokens` becomes `input_tokens`.
- `completion_tokens` becomes `output_tokens`.
- `cost` becomes `cost_amount`.
- `occurred_at` is backfilled from `created_at`.
- OpenRouter positive historical costs become `provider`.
- Non-OpenRouter positive historical costs become `manual_response`.
- New cache/reasoning counters default to zero.

## 8. Final Release Commands

Run from the repository:

```bash
bin/test
env RUBOCOP_CACHE_ROOT=/private/tmp/rubocop_cache bin/rubocop
gem build open_router_usage_tracker.gemspec --output /private/tmp/open_router_usage_tracker.gem
gem specification /private/tmp/open_router_usage_tracker.gem files | rg "README.md|CHANGELOG.md|docs/"
```

Then verify GitHub Actions passes for the Ruby/Rails/database matrix before publishing.
