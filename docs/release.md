# Release Guide

This gem follows a conservative release policy because it writes accounting data.

## Supported Matrix

As of 2026-04-29:

- Ruby: 3.2, 3.3, and 3.4.
- Rails: 8.0 and 8.1, matching the gemspec's `~> 8.0` dependency.
- Databases in CI: SQLite and PostgreSQL.

References:

- Rails releases: https://www.rubyonrails.org/releases
- Rails Guides v8.1.3: https://guides.rubyonrails.org/
- Rails 8.1 Ruby requirement: https://rubygems.org/gems/rails/versions/8.1.0
- Ruby releases: https://www.ruby-lang.org/en/news/2026/
- RubyGems Guides: https://guides.rubygems.org/
- Keep a Changelog 1.1.0: https://keepachangelog.com/en/1.1.0/

## Versioning Policy

- Patch releases: parser fixes, fixture updates, documentation corrections, and bug fixes that do not change persisted schema or public method contracts.
- Minor releases: provider support, optional configuration, maintenance tasks, or query helpers when existing apps keep working without migration.
- Major releases: schema changes, renamed persisted columns, changed cost semantics, removed public APIs, or default behavior changes that can affect accounting totals.

## v2 Release Plan

Ship v2 as version `2.0.0` because it renames token/cost columns, adds cost metadata, and changes parser failures from ambiguous model validation errors to explicit `OpenRouterUsageTracker::ParseError` exceptions.

Before publishing:

1. Run `bin/test`.
2. Run `env RUBOCOP_CACHE_ROOT=/private/tmp/rubocop_cache bin/rubocop`.
3. Run the GitHub Actions CI matrix.
4. Confirm `bin/rails g open_router_usage_tracker:upgrade_v2` works in a disposable host app.
5. Review `CHANGELOG.md` for breaking changes and upgrade steps.
6. Build the gem with `gem build open_router_usage_tracker.gemspec --output /private/tmp/open_router_usage_tracker.gem`.
7. Tag the release only after the upgrade generator and README instructions match the shipped schema.

## Upgrade Path

Existing v1 applications should:

1. Upgrade the gem.
2. Generate the v2 migration with `bin/rails g open_router_usage_tracker:upgrade_v2`.
3. Review the migration for local custom columns or indexes.
4. Run `bin/rails db:migrate`.
5. Rebuild daily summaries with `bin/rails open_router_usage_tracker:summaries:rebuild` if historical summary totals need the new cache/reasoning/detail fields.
