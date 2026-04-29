# Agent Operating Contract

This is the working agreement for autonomous or AI-assisted engineering in this repository.

## Mission

Protect the gem's business promise: every successful LLM request that matters to billing or limits should become accurate, queryable, user-scoped usage data. Code changes should make that promise more reliable without pushing provider-specific accounting into host Rails apps.

## Loop

1. Orient in the public API, tests, migrations, and code path being changed.
2. Verify current provider behavior when response shapes or pricing may have changed.
3. Pick one high-value target with a clear user or operator benefit.
4. Write or update regression tests before changing behavior when practical.
5. Make the smallest production change that satisfies the behavior.
6. Run focused tests, then the full suite.
7. Run lint/style checks.
8. Read the diff as a reviewer.
9. Update docs or changelog when setup, behavior, or operations changed.
10. Move to the next target only after the current one is green and understandable.

## Engineering Rules

- Prefer Rails and ActiveRecord primitives already used by the gem.
- Keep provider-specific code inside parsers or explicit provider abstractions.
- Treat money, tokens, idempotency, migrations, and deletion behavior as high-risk surfaces.
- Avoid broad refactors unless they remove real ambiguity or make future provider work safer.
- Preserve provider detail that could matter for billing reconciliation by normalizing it or keeping it in raw/details JSON.
- Write tests around provider fixtures, duplicate requests, summary updates, timezone/day boundaries, and upgrade generators.

## Definition Of Done

- Behavior is covered by a regression test, or the reason for no test is explicit.
- `bin/test` passes.
- `bin/rubocop` passes, with cache redirected to a writable path if needed.
- The diff is scoped to the problem.
- New behavior is documented when it affects host app integration.
- Remaining risks are captured in `docs/pipeline.md` or an issue-sized follow-up note.

## Autonomy Boundaries

- Fix small, high-confidence bugs immediately.
- Make additive, backward-compatible features when tests and docs travel with the code.
- Stop before destructive git actions, schema-breaking changes, publishing, or removing public API unless explicitly asked.
- Preserve user changes in the worktree and avoid unrelated cleanup.

## Review Checklist

- Does the parser match current provider response shapes?
- Does logging stay idempotent for provider/request ids?
- Can concurrent writes double-count, under-count, or fail?
- Are costs stored with enough precision and clear units?
- Does deleting a user do what the host app intentionally configured?
- Can a host app enforce limits without expensive aggregate queries?
- Can an operator audit what happened after an incident?
