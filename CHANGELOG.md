# Changelog

All notable changes to this project are documented here. The format follows the spirit of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), with newest releases first.

## 2.0.0 (Unreleased)

### Added

- Normalized parser contract through `OpenRouterUsageTracker::NormalizedUsage`.
- Explicit `OpenRouterUsageTracker::ParseError` failures for malformed provider responses.
- Provider response fixture coverage based on official OpenRouter, OpenAI, Anthropic, Google, and xAI usage shapes.
- v2 lean usage-accounting schema with input/output tokens, cache/reasoning counters, cost metadata, `usage_details`, and `occurred_at`.
- `open_router_usage_tracker:upgrade_v2` for existing installations.
- Config-first model pricing through `OpenRouterUsageTracker.configure`.
- Range helpers for token totals, request counts, cost totals, and usage totals.
- `occurred_at` logging and duplicate request policies.
- Raw response redaction, raw response pruning, daily summary rebuild maintenance, and `log.open_router_usage_tracker` notifications.
- CI coverage for Rails 8.0/8.1, Ruby 3.2-3.4, SQLite, and PostgreSQL.
- Focused documentation under `docs/`.
- Detailed integration examples and v2 release review checklist documentation.

### Changed

- Refactored provider parsing into `providers/` and log persistence into `persistence/` while keeping `OpenRouterUsageTracker.log` as the public entry point.
- Renamed prompt/completion accounting language to input/output accounting.
- Counted Anthropic cache creation/read tokens in input and total token accounting.
- Made daily summary updates safer under concurrent logging.
- Prevented install generator migration timestamp collisions.
- Bumped the gem version and install docs to `2.0.0`.

## 1.0.4 (2025-11-17)

### Changed

- Updated gemspec dependency to `"rails", "~> 8.0"`.

## 1.0.0 (2025-07-30)

### Removed

- Removed `usage_today` and `cost_exceeded?` from `Trackable`.

### Changed

- `Trackable` no longer sets `dependent: :destroy` on usage associations; host apps must configure retention explicitly.
- Daily summaries now include `provider` and `model`.
- Usage logs now include `provider`.
- Unique usage log index changed to `[:provider, :request_id]`.
- `daily_usage_summary_for` now requires an explicit `day`.

### Added

- Multi-provider/model usage tracking.
- `Trackable#total_cost_in_range`.
- More resilient parser behavior for missing or `nil` response values.

## 0.2.0 (2025-06-28)

### Added

- Performant daily rate-limiting through the `open_router_daily_summaries` table.
- `open_router_usage_tracker:summary_install` generator.
- `usage_today` and `cost_exceeded?(limit:)` helpers.

### Deprecated

- Deprecated `usage_in_last_24_hours` for rate-limiting in favor of summary-backed helpers.
