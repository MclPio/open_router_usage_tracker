# Project Context for `open_router_usage_tracker`

This document provides a summary of the key files and architecture of this gem to quickly onboard an AI assistant.

---

## Core Logic

These files contain the primary business logic of the gem.

*   `lib/open_router_usage_tracker.rb`
    *   **Purpose**: The main module and entry point for the gem. It contains the primary public method, `OpenRouterUsageTracker.log`.
    *   **Recent Changes**: The `log` method was significantly refactored. It now wraps the creation of a `UsageLog` and the update to the `DailySummary` in a single database transaction to ensure data integrity.

*   `app/models/open_router_usage_tracker/usage_log.rb`
    *   **Purpose**: The ActiveRecord model representing a single, detailed API call. This is the primary log table.

*   `app/models/open_router_usage_tracker/daily_summary.rb`
    *   **Purpose**: A new model introduced to store aggregated daily usage data (tokens and cost) for each user. This table is designed to be small and fast to query, forming the foundation of the new rate-limiting feature.

*   `app/models/concerns/open_router_usage_tracker/trackable.rb`
    *   **Purpose**: A concern intended to be included in the host application's `User` model (or equivalent).
    *   **Recent Changes**: This module was updated to add the `has_many :daily_summaries` association and two new helper methods: `usage_today` and `cost_exceeded?(limit:)`, which query the new summary table.

---

## Generators

These files are responsible for integrating the gem into a host Rails application.

*   `lib/generators/open_router_usage_tracker/install/install_generator.rb`
    *   **Purpose**: The original generator that creates the migration for the `open_router_usage_logs` table.

*   `lib/generators/open_router_usage_tracker/summary_install/summary_install_generator.rb`
    *   **Purpose**: A new generator created to add the migration for the `open_router_daily_summaries` table. This was created as a separate generator to allow existing users to upgrade and add the new table without re-running the initial install.

---

## Testing

The gem uses the standard Rails testing framework within a dummy application.

*   `test/dummy/app/models/user.rb`
    *   **Purpose**: The dummy `User` model used for testing. It was updated to include `OpenRouterUsageTracker::Trackable` so that the new helper methods could be tested.

*   `test/models/open_router_usage_tracker/daily_summary_test.rb`
    *   **Purpose**: A new test file written to validate the creation and atomic updating of `DailySummary` records via the `log` method, including handling of concurrent requests.

*   `test/models/concerns/open_router_usage_tracker/trackable_summary_test.rb`
    *   **Purpose**: A new test file written to validate the new `usage_today` and `cost_exceeded?` helper methods in the `Trackable` concern.

---

## Documentation

*   `README.md`
    *   **Purpose**: The primary user-facing documentation.
    *   **Recent Changes**: Updated to explain the new daily summary feature, add instructions for the new generator, and officially recommend the `cost_exceeded?` method for rate-limiting while deprecating the old approach.

*   `CHANGELOG.md`
    *   **Purpose**: Tracks changes for each version.
    *   **Recent Changes**: Updated to reflect all the new features and changes for version `0.2.0`.
