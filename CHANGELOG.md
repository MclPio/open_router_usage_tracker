# CHANGELOG

## 1.0.4 (2025-11-17)

*   Update gemspec dependency. `"rails", "~> 8.0"`

## 1.0.0 (2025-07-30)

### Breaking Changes

*   The `Trackable` concern no longer sets `dependent: :destroy` on its associations. You must now configure this behavior in your `User` model. See the README for details.
*   The `usage_today` and `cost_exceeded?` methods have been removed from the `Trackable` concern.
*   The `daily_summaries` table now includes `provider` and `model` columns. The unique index is now on `[:user_type, :user_id, :day, :provider, :model]`.
*   The `usage_logs` table now includes a `provider` column. The unique index on `request_id` is now a composite index on `[:provider, :request_id]`.

### Features

*   **Multi-Provider/Model Usage Tracking**: Track usage and cost for each provider and model combination separately.
*   **New `Trackable` Helper**: Added `total_cost_in_range` to the `Trackable` concern to easily calculate costs over a date range.
*   **Explicit Date Handling**: The `daily_usage_summary_for` method now requires an explicit `day` parameter to avoid timezone-related bugs.

### Improvements

*   **Parser Robustness**: Parsers are now more resilient to missing or `nil` values in API responses.
*   **Documentation**: The `README.md` and `gemspec` have been polished for clarity and now include information about multi-provider support.

## 0.2.0 (2025-06-28)

*   **Feature: Performant Daily Rate-Limiting.** Introduced a new `open_router_daily_summaries` table to provide high-performance, daily usage tracking. This avoids slow `SUM` queries on the main log table, making it suitable for production rate-limiting.
*   **New Generator.** Added a new generator `open_router_usage_tracker:summary_install` to create the migration for the new summary table.
*   **New `Trackable` Helpers.** Added `usage_today` and `cost_exceeded?(limit:)` to the `Trackable` concern for near-instantaneous checks against the daily summary.
*   **DEPRECATION.** `usage_in_last_24_hours` is now deprecated for rate-limiting in favor of the more performant `cost_exceeded?` method.