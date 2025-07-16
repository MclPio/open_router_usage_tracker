# Project Context for `open_router_usage_tracker`

This document provides a summary of the key files and architecture of this gem to quickly onboard an AI assistant.

---

## Core Logic

These files contain the primary business logic of the gem.

*   `lib/open_router_usage_tracker.rb`
    *   **Purpose**: The main module for the gem. It now includes the `Adapter::Base` module to handle the core logging functionality.

*   `lib/open_router_usage_tracker/adapter/base.rb`
    *   **Purpose**: This new file contains the main `log` method, which is responsible for parsing the API response, creating a `UsageLog`, and updating the `DailySummary`. It uses a parser class based on the `provider` parameter.

*   `lib/open_router_usage_tracker/parsers/`
    *   **Purpose**: This new directory contains parser classes for each supported provider (e.g., `open_ai.rb`, `open_router.rb`). Each parser is responsible for extracting the usage data from the provider-specific response format.

*   `app/models/open_router_usage_tracker/usage_log.rb`
    *   **Purpose**: The ActiveRecord model representing a single, detailed API call. 
    *   **Recent Changes**: The validations have been updated to be more flexible. Instead of requiring presence, `prompt_tokens`, `completion_tokens`, `total_tokens`, and `cost` now have numericality validations (>= 0) to support a wider range of provider responses.

*   `app/models/open_router_usage_tracker/daily_summary.rb`
    *   **Purpose**: An ActiveRecord model to store aggregated daily usage data for each user.
    *   **Recent Changes**: This model was updated to include `prompt_tokens` and `completion_tokens` to provide more detailed daily summaries.

*   `app/models/concerns/open_router_usage_tracker/trackable.rb`
    *   **Purpose**: A concern to be included in the host application's `User` model. It provides helper methods for querying usage data.

---

## Generators

These files are responsible for integrating the gem into a host Rails application.

*   `lib/generators/open_router_usage_tracker/install/install_generator.rb`
    *   **Purpose**: Creates the migration for the `open_router_usage_logs` table. The template for this migration has been updated to set default values for the token and cost fields.

*   `lib/generators/open_router_usage_tracker/summary_install/summary_install_generator.rb`
    *   **Purpose**: Creates the migration for the `open_router_daily_summaries` table. The template has been updated to include `prompt_tokens` and `completion_tokens`.

---

## Testing

The gem uses the standard Rails testing framework within a dummy application.

*   `test/open_router_usage_tracker_test.rb`
    *   **Purpose**: Contains tests for the main `OpenRouterUsageTracker.log` method, including new tests for the multi-provider support.

*   `test/models/open_router_usage_tracker/usage_log_test.rb`
    *   **Purpose**: Contains tests for the `UsageLog` model. The tests have been updated to reflect the new numericality validations.

*   `test/models/open_router_usage_tracker/daily_summary_test.rb`
    *   **Purpose**: Contains tests for the `DailySummary` model, including new tests to verify that `prompt_tokens` and `completion_tokens` are correctly saved.

---

## Documentation

*   `README.md`
    *   **Purpose**: The primary user-facing documentation.
    *   **Recent Changes**: Updated to explain the new multi-provider support, add instructions for the `provider` parameter in the `log` method, and update the architecture diagrams.

*   `CHANGELOG.md`
    *   **Purpose**: Tracks changes for each version.
    *   **Recent Changes**: Updated to reflect all the new features and changes for version `0.2.0`.
