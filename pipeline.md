# OpenRouterUsageTracker Pipeline

As of 2026-04-28, this gem solves a concrete Rails business problem: LLM-backed products need a durable, user-scoped ledger of token usage and cost so teams can enforce plan limits, prevent runaway spend, audit requests, and build usage-based billing without binding application code to one provider.

The current architecture is intentionally small: provider parsers normalize raw API responses, `UsageLog` stores the auditable request record, `DailySummary` stores fast per-user/provider/model totals, and `Trackable` gives host apps query helpers.

## Provider Surface Checked

- OpenRouter usage accounting: usage is returned automatically, including prompt/completion/total tokens, cost, cache, reasoning, and cost detail fields.
  Source: https://openrouter.ai/docs/guides/administration/usage-accounting
- OpenRouter API response shape: streaming returns usage once in the final chunk; response usage may include detail fields and cost metadata.
  Source: https://openrouter.ai/docs/api/reference/overview
- OpenAI Responses API: usage uses `input_tokens`, `output_tokens`, and `total_tokens`.
  Source: https://platform.openai.com/docs/api-reference/responses/create
- OpenAI Chat Completions API: usage uses `prompt_tokens`, `completion_tokens`, and `total_tokens`.
  Source: https://platform.openai.com/docs/api-reference/chat/object
- Anthropic Messages API: billing/rate-limit usage includes input, output, cache creation, and cache read token fields.
  Source: https://docs.anthropic.com/en/api/messages
- Google Gemini GenerateContent API: `usageMetadata` includes prompt, candidates, cache, tool-use, thoughts, and total token counts.
  Source: https://ai.google.dev/api/generate-content
- xAI Chat Completions and Responses usage: chat uses prompt/completion token fields; Responses uses input/output token fields.
  Source: https://docs.x.ai/developers/advanced-api-usage/prompt-caching/usage-and-pricing

## Milestone 0: First Hardening Pass

Status: completed in this pass.

- Support both OpenAI Responses and Chat Completions usage shapes.
- Support both xAI Chat Completions and Responses usage shapes.
- Count Anthropic cache creation/read tokens in prompt and total token accounting.
- Update daily summaries with `create_or_find_by!` plus row locking to avoid duplicate-summary races and lost increments under concurrent logging.
- Make generator migration numbers advance past existing timestamps so `install` and `summary_install` cannot collide when run in the same second.
- Add regression coverage and run the full test suite plus RuboCop.

## Milestone 1: Parser Contract And Fixture Corpus

- Introduce a small internal parser contract that all providers satisfy: `model`, `request_id`, `prompt_tokens`, `completion_tokens`, `total_tokens`, `cost`, and `details`.
- Add provider fixture files from current API docs for streaming-final chunks, non-streaming responses, cached requests, reasoning requests, and missing-cost cases.
- Fail with explicit parser errors when required keys are missing instead of relying on model validations to surface ambiguous `nil` or zero values.
- Keep raw responses optional, but preserve normalized details even when raw response storage is disabled.

## Milestone 2: Usage Detail Storage

- Add an optional `usage_details` JSON column to logs and summaries.
- Normalize provider-specific details into stable keys: cached tokens, cache writes, reasoning tokens, audio/image/video tokens, tool-use tokens, service tier, BYOK metadata, and upstream cost details.
- Keep the current top-level columns as the fast path for existing queries.
- Add migration/generator upgrades for applications already using the gem.

## Milestone 3: Cost Engine

- Add configurable model pricing so OpenAI, Anthropic, Google, and xAI calls can have costs even when providers do not return cost directly.
- Represent currency/credits explicitly so OpenRouter credits are not confused with USD.
- Support cached-token and reasoning-token pricing modifiers.
- Provide a clear override hook for host apps that already calculate cost.

## Milestone 4: Rate-Limit And Billing APIs

- Add range helpers for token totals, request counts, and cost totals by provider/model.
- Add a `log(..., occurred_at:)` or `day:` option so host apps can align summaries to a user's timezone or a provider event timestamp.
- Add optional idempotency behavior: raise, return existing log, or no-op on duplicate provider/request IDs.
- Provide example policies for daily token caps, monthly spend caps, and per-model plan limits.

## Milestone 5: Operations And Privacy

- Add configurable redaction for raw responses before persistence.
- Add retention helpers or documentation for pruning raw responses while keeping normalized aggregates.
- Add backfill/recompute tasks for daily summaries from usage logs.
- Add PostgreSQL-focused guidance for `jsonb`, decimal precision, and high-write workloads.
- Add instrumentation hooks through `ActiveSupport::Notifications`.

## Milestone 6: Release Readiness

- Expand CI across supported Ruby, Rails, SQLite, and PostgreSQL versions.
- Document breaking-change policy and upgrade paths.
- Add generator tests for both install generators and existing-migration collisions.
- Prepare a minor release for backward-compatible fixes and a major release for schema/API additions.

