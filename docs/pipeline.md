# Project Pipeline

This is a historical project plan for the v2 hardening work. It is not the main user guide. Start with the [README](../README.md), then read [usage](usage.md) or [architecture](architecture.md) depending on what you need.

As of 2026-04-29, this gem solves a concrete Rails business problem: LLM-backed products need a durable, user-scoped ledger of token usage and cost so teams can enforce plan limits, prevent runaway spend, audit requests, and build usage-based billing without binding application code to one provider.

## Provider Surface Checked

- OpenRouter usage accounting: https://openrouter.ai/docs/guides/administration/usage-accounting
- OpenRouter API overview: https://openrouter.ai/docs/api/reference/overview
- OpenAI Responses API: https://platform.openai.com/docs/api-reference/responses/create
- OpenAI Chat Completions API: https://platform.openai.com/docs/api-reference/chat/object
- Anthropic Messages API: https://docs.anthropic.com/en/api/messages
- Google Gemini GenerateContent API: https://ai.google.dev/api/generate-content
- xAI usage and pricing notes: https://docs.x.ai/developers/advanced-api-usage/prompt-caching/usage-and-pricing

## Completed Milestones

### Milestone 0: First Hardening Pass

- Supported both OpenAI Responses and Chat Completions usage shapes.
- Supported both xAI Chat Completions and Responses-style usage shapes.
- Counted Anthropic cache creation/read tokens in input and total token accounting.
- Made daily summary updates safer under concurrent logging.
- Prevented generator migration timestamp collisions.

### Milestone 1: Parser Contract And Fixture Corpus

- Introduced `OpenRouterUsageTracker::NormalizedUsage`.
- Added official-doc-inspired provider fixtures for OpenRouter, OpenAI, Anthropic, Google, and xAI.
- Added explicit `OpenRouterUsageTracker::ParseError` failures for malformed provider responses.
- Preserved normalized details separately from optional raw response storage.

### Milestone 1.5: Architecture And File Structure Review

- Kept the public gem/module name `OpenRouterUsageTracker`.
- Moved provider parsing from `parsers/` into `providers/`.
- Added a provider registry.
- Extracted `persistence/usage_recorder` and `persistence/daily_summary_updater`.
- Kept `OpenRouterUsageTracker.log` as the stable public entry point.

### Milestone 2: Lean Usage Accounting Schema

- Chose a lean default schema over modality-specific install profiles.
- Renamed prompt/completion accounting to input/output accounting.
- Added cache/reasoning counters, cost metadata, `usage_details`, raw response storage, and `occurred_at`.
- Added `open_router_usage_tracker:upgrade_v2`.
- Aggregated numeric usage details into daily summaries.

### Milestone 3: Cost Engine

- Chose config-first pricing instead of bundled live pricing.
- Treated provider-returned cost as authoritative when present.
- Added exact provider/model pricing through `OpenRouterUsageTracker.configure`.
- Added source-aware cost calculation for input, output, cache read/write, and reasoning output tokens.
- Preserved manual response cost overrides.

### Milestone 4: Rate-Limit And Billing APIs

- Added range helpers for token totals, request counts, cost totals, and usage-total hashes.
- Added `log(..., occurred_at:)`.
- Added duplicate request policies: `:raise`, `:return_existing`, and `:ignore`.
- Kept `:raise` as the default accounting behavior.

### Milestone 5: Operations And Privacy

- Added configurable raw response redaction.
- Added raw response pruning and daily summary rebuild services.
- Added rake tasks for maintenance.
- Added PostgreSQL guidance for `jsonb`, decimal precision, and high-write workloads.
- Added `log.open_router_usage_tracker` ActiveSupport notifications.

### Milestone 6: Release Readiness

- Expanded CI across Ruby 3.2, 3.3, and 3.4.
- Expanded CI across Rails 8.0 and 8.1.
- Added SQLite and PostgreSQL CI coverage.
- Added generator collision tests.
- Added release policy and upgrade checklist in [release.md](release.md).
- Bumped the gem version and install docs to `2.0.0`.

## Current Documentation Decision

The docs have been split so the README stays short and focused:

- `README.md`: entry point.
- `docs/usage.md`: host app integration.
- `docs/integration_examples.md`: real integration examples and public API argument types.
- `docs/architecture.md`: contributor codebase guide.
- `docs/release.md`: release policy and checklist.
- `docs/v2_release_review.md`: pre-release repository review and dummy-app test checklist.
- `docs/agent.md`: autonomous engineering workflow.
- `docs/pipeline.md`: this historical plan.
