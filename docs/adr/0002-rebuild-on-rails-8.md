# ADR-0002: Rebuild on Rails 8 instead of upgrading the legacy app

- Status: Proposed
- Date: 2026-11-06

## Context

The existing app (Ruby 3.0.2, Rails 6.1, Webpacker) models each client campaign as its own
tables, controllers and views, and models roles as per-campaign boolean flags on `users`
([00](../architecture/00-legacy-assessment.md)). It has no tenancy and only scaffold tests.
The new platform's core is the opposite: generic, versioned forms; tenant isolation; roles via
memberships. Ruby 3.0 is end-of-life and Webpacker is retired.

## Decision

Start a new Rails 8 application (latest stable Rails and Ruby at scaffold time) in this
repository. Tag the current state `legacy-v1`. The first implementation PR replaces the legacy
code with the new skeleton. Legacy campaign data is migrated only if the product owner confirms
it is needed, via a one-off importer into the generic form/submission model.

## Consequences

- No time spent upgrading code that would then be deleted.
- History and lessons are preserved (tag + legacy assessment doc).
- Any live users of the legacy app need a cut-over plan (to be confirmed: is it still in use?).

## Alternatives considered

- **Incremental upgrade (6.1 → 7 → 8) then refactor** — touches every file twice; the data and
  role models would still need replacing; high effort, little retained value.
- **New repository** — loses issue/PR history and continuity for no technical benefit.
