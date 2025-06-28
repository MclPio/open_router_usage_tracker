# CHANGELOG

## 0.2.0 (2025-06-28)

*   **Feature: Performant Daily Rate-Limiting.** Introduced a new `open_router_daily_summaries` table to provide high-performance, daily usage tracking. This avoids slow `SUM` queries on the main log table, making it suitable for production rate-limiting.
*   **New Generator.** Added a new generator `open_router_usage_tracker:summary_install` to create the migration for the new summary table.
*   **New `Trackable` Helpers.** Added `usage_today` and `cost_exceeded?(limit:)` to the `Trackable` concern for near-instantaneous checks against the daily summary.
*   **DEPRECATION.** `usage_in_last_24_hours` is now deprecated for rate-limiting in favor of the more performant `cost_exceeded?` method.
