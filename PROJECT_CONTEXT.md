# Project Context for `open_router_usage_tracker`

This document provides a summary of the key files and architecture of this gem to quickly onboard an AI assistant.

---

## Core Logic

These files contain the primary business logic of the gem.

*   `lib/open_router_usage_tracker.rb`
    *   **Purpose**: The main module for the gem. It includes the `Adapter::Base` module to handle the core logging functionality.

*   `lib/open_router_usage_tracker/adapter/base.rb`
    *   **Purpose**: This file contains the main `log` method, which is responsible for parsing the API response, creating a `UsageLog`, and updating the `DailySummary`. It uses a parser class based on the `provider` parameter.

*   `lib/open_router_usage_tracker/parsers/`
    *   **Purpose**: This new directory contains parser classes for each supported provider (e.g., `open_ai.rb`, `open_router.rb`). Each parser is responsible for extracting the usage data from the provider-specific response format.

*   `app/models/open_router_usage_tracker/usage_log.rb`
    *   **Purpose**: The ActiveRecord model representing a single, detailed API call. 
    *   **Recent Changes**: The uniqueness validation for `request_id` is now scoped to the `provider`.

*   `app/models/open_router_usage_tracker/daily_summary.rb`
    *   **Purpose**: An ActiveRecord model to store aggregated daily usage data for each user, provider, and model combination.
    *   **Recent Changes**: This model now includes `provider` and `model` columns. The uniqueness validation is now on the combination of `user`, `day`, `provider`, and `model`.

*   `app/models/concerns/open_router_usage_tracker/trackable.rb`
    *   **Purpose**: A concern to be included in the host application's `User` model. It provides helper methods for querying usage data.
    *   **Recent Changes**: The `usage_today` and `cost_exceeded?` methods have been removed. The primary methods are now `daily_usage_summary_for(day:, provider:, model:)` for specific daily checks, and `total_cost_in_range(range, provider:, model: nil)` for calculating costs over a period. The `dependent: :destroy` option has been removed from the associations, requiring developers to configure this in their `User` model.

---

## Generators

These files are responsible for integrating the gem into a host Rails application.

*   `lib/generators/open_router_usage_tracker/install/install_generator.rb`
    *   **Purpose**: Creates the migration for the `open_router_usage_logs` table. The template for this migration has been updated to include a `provider` column and a composite unique index on `[:provider, :request_id]`.

*   `lib/generators/open_router_usage_tracker/summary_install/summary_install_generator.rb`
    *   **Purpose**: Creates the migration for the `open_router_daily_summaries` table. The template has been updated to include `provider` and `model` columns, and the unique index is now on `[:user_type, :user_id, :day, :provider, :model]`.

---

## Testing

The gem uses the standard Rails testing framework within a dummy application.

*   `test/`
    *   **Purpose**: Contains all the tests for the gem.
    *   **Recent Changes**: Tests have been updated to reflect the new API and database schema. New tests have been added to cover the multi-provider and multi-model functionality.

Notable Test Files:

*   `test/open_router_usage_tracker_test.rb`
    *  **Purpose**: Contains most tests of the gem, testing parsers, log, daily_summary, and more!

*   `test/models/concerns/open_router_usage_tracker/trackable_test.rb`
    * **Purpose**: tests trackable concern dependent behavior and method daily_usage_summary_for

*   `test/models/open_router_usage_tracker/daily_summary_test.rb`
    * **Purpose**: unit tests for daily_summary model

*   `test/models/open_router_usage_tracker/usage_log_test.rb`
    * **Purpose**: unit tests for usage_log model
---

## Documentation

*   `README.md`
    *   **Purpose**: The primary user-facing documentation.
    *   **Recent Changes**: Updated to reflect the new API, the removal of `dependent: :destroy`, and the new `provider` and `model` parameters.

*   `CHANGELOG.md`
    *   **Purpose**: Tracks changes for each version.
    *   **Recent Changes**: Updated to reflect all the new features and breaking changes for version `1.0.0`.