# Suggested Issues for `open_router_usage_tracker`

Here are four feature suggestions to improve the gem, focusing on simplicity, power, and developer experience.

---

### Issue #1: The Foundational Refactor for Growth

**Title: Feature: Make the Gem Provider-Agnostic via an Adapter Pattern**

**Problem/Motivation:**

Right now, the gem is `OpenRouterUsageTracker`. To become the #1 tool, it needs to be the `ApiUsageTracker`. The biggest barrier to adoption is the hard dependency on OpenRouter's specific API response structure. A developer using OpenAI, Anthropic, or Google's API directly can't use this gem. We need to break that coupling.

This is a classic Sandi Metz-style design improvement: make dependencies explicit and swappable to prepare for future change.

**Proposed Solution:**

1.  **Introduce an Adapter Pattern.** The `log` method should be decoupled from parsing the response. We can create a system of adapters whose job is to translate a provider-specific response into a standardized hash that the rest of the gem can work with.

2.  **Refactor `log` Method.** The `log` method signature would change to accept a `provider` or `adapter`.
    ```ruby
    # The new, flexible log method
    OpenRouterUsageTracker.log(response: api_response, user: current_user, provider: :open_router)
    ```

3.  **Create Adapters.** Create a base adapter and specific implementations.
    *   `lib/open_router_usage_tracker/adapters/base.rb` would define the interface.
    *   `lib/open_router_usage_tracker/adapters/open_router_adapter.rb` would contain the current logic for parsing OpenRouter responses.
    *   `lib/open_router_usage_tracker/adapters/open_ai_adapter.rb` could be a new adapter for parsing direct OpenAI API responses.

4.  **Update Documentation.** This becomes a major selling point. The README would show how easy it is to track usage from multiple providers.

**Expected Outcome:**

A developer can now use the gem to track usage from any LLM provider by simply specifying the correct provider. This dramatically expands the potential user base and makes the gem a truly universal tool.

---

### Issue #2: The "Wow" Feature for Instant Value

**Title: Feature: Add a Basic Admin Dashboard Engine**

**Problem/Motivation:**

The gem is great at *collecting* data, but developers still have to do the work to *see* it. The single biggest "wow" factor you could add is a pre-built, zero-config UI. This provides immediate, tangible value and makes the gem feel like a complete solution, not just a library.

**Proposed Solution:**

1.  **Create a new Rails Engine.** Within the gem, create a simple, mountable Rails Engine.
2.  **Define Routes.** The engine would have routes like `/usage_tracker` that an admin could visit.
3.  **Build Simple Views.** Create a few server-rendered ERB views:
    *   A main dashboard showing total cost and tokens for the last 24 hours and the last month.
    *   A page to view usage per user, with basic search.
    *   (Bonus) Simple charts using a lightweight library like Chart.js to visualize cost over time.
4.  **Update Documentation.** Add a section explaining how to mount the engine in their `config/routes.rb`:
    ```ruby
    # config/routes.rb
    mount OpenRouterUsageTracker::Engine, at: "/admin/usage"
    ```

**Expected Outcome:**

A developer can install the gem, run the migrations, and immediately have a working dashboard to monitor their application's API costs. This is an incredibly powerful selling point.

---

### Issue #3: The Professional Polish Feature

**Title: Improvement: Introduce a Configuration Initializer**

**Problem/Motivation:**

Great gems are flexible. Right now, the gem makes assumptions. For example, it assumes the trackable model is called `User`. What if it's `Account` or `Team`? A professional-grade tool should allow for easy configuration. This follows the Rails convention of using initializer files for setup.

**Proposed Solution:**

1.  **Create a Configuration Class.**
    ```ruby
    # lib/open_router_usage_tracker/configuration.rb
    module OpenRouterUsageTracker
      class Configuration
        attr_accessor :user_class, :enable_daily_summaries
        # ... with defaults
      end
    end
    ```
2.  **Add a Generator for the Initializer.** Create a simple generator that creates the following file:
    ```ruby
    # config/initializers/open_router_usage_tracker.rb
    OpenRouterUsageTracker.configure do |config|
      # The model class that includes the Trackable concern.
      # config.user_class = "User"

      # Set to false to disable the creation of daily summary records.
      # config.enable_daily_summaries = true
    end
    ```
3.  **Refactor the Codebase.** Update the `Trackable` concern and `log` method to reference the configuration values (e.g., `OpenRouterUsageTracker.configuration.user_class.constantize`).

**Expected Outcome:**

The gem becomes more flexible and easier to integrate into a wider variety of Rails applications, making it feel more robust and professional.

---

### Issue #4: The Logical Next Step for Power Users

**Title: Feature: Support for Monthly and Hourly Summary Tracking**

**Problem/Motivation:**

Daily rate-limiting is a fantastic start, but real-world applications have more complex needs.
*   **Monthly limits** are essential for aligning with user billing cycles.
*   **Hourly limits** are useful for preventing short-term abuse or "runaway script" scenarios.

**Proposed Solution:**

1.  **Enhance the Summary Logic.** Instead of just a `DailySummary`, you could introduce `HourlySummary` and `MonthlySummary` tables and models.
2.  **Update the `log` Method.** The transaction in the `log` method would now update three tables: the raw log, the hourly summary, and the daily summary. A background job could aggregate the hourly/daily data into monthly summaries to keep requests fast.
3.  **Expand `Trackable` Helpers.** Add new, intuitive methods to the concern:
    ```ruby
    current_user.cost_exceeded?(limit: 100.00, period: :monthly)
    current_user.usage_this_hour
    current_user.usage_this_month
    ```

**Expected Outcome:**

The gem evolves from a simple daily tracker into a comprehensive cost management and rate-limiting tool that can handle the most common business requirements out of the box.
