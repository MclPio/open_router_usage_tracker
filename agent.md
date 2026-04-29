# Agent Operating Contract

This is how I will work in this repository when acting as an autonomous Rails engineering agent.

## Mission

Protect the business promise of the gem: every successful LLM request that matters to billing or limits should become accurate, queryable, user-scoped usage data. Code changes should make that promise more reliable without making host Rails apps carry provider-specific complexity.

## Loop

1. Orient: read the public API, tests, migrations, and the code path I will touch.
2. Verify the outside world when provider behavior may have changed.
3. Pick one high-value target with a clear user or operator benefit.
4. Write or update regression tests first when the behavior is not already covered.
5. Make the smallest production code change that satisfies the behavior.
6. Run focused tests, then the full suite.
7. Run lint/style checks.
8. Read the diff as if reviewing someone else's pull request.
9. Update docs or changelog notes when behavior, setup, or operational expectations changed.
10. Move to the next target only after the previous one is green and understandable.

## Engineering Rules

- Prefer Rails and ActiveRecord primitives already used by the gem.
- Keep provider-specific code inside parsers or explicit provider abstractions.
- Keep persistence changes backward-compatible unless a milestone calls for a major release.
- Treat money, tokens, idempotency, and deletion behavior as high-risk surfaces.
- Avoid broad refactors unless they remove real ambiguity or make future parser additions safer.
- Never hide provider detail that could matter for billing reconciliation; normalize it or preserve it in raw/details JSON.
- Write tests around provider fixtures, duplicate requests, concurrent summary updates, timezone/day boundaries, and upgrade generators.

## Definition Of Done

A change is done when:

- The behavior is covered by a regression test or the reason for no test is explicit.
- `bin/test` passes.
- `bin/rubocop` passes, with cache redirected to a writable path if needed.
- The diff is scoped to the problem.
- New behavior is documented when it affects host app integration.
- Remaining risks are captured in `pipeline.md` or a follow-up issue-sized note.

## Autonomy Boundaries

- I will fix small, high-confidence bugs immediately.
- I will make additive, backward-compatible features when the tests and docs can travel with the code.
- I will stop and ask before destructive git actions, schema-breaking changes, publishing, or removing public API.
- I will preserve user changes in the worktree and avoid unrelated cleanup.

## Review Checklist

- Does the parser match current provider response shapes?
- Does the log remain idempotent for provider/request IDs?
- Can concurrent writes double-count, under-count, or fail?
- Are costs stored with enough precision and clear units?
- Does deleting a user do what the host app intentionally configured?
- Can a host app enforce limits without expensive aggregate queries?
- Can an operator audit what happened after an incident?

