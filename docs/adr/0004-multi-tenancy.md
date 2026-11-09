# ADR-0004: Shared-schema multi-tenancy with app scoping and Postgres RLS

- Status: Proposed
- Date: 2026-11-06

## Context

Agencies are tenants; each has clients, projects, members and submissions. A cross-tenant leak
is the worst possible failure after data loss. We expect hundreds of agencies per cell, many of
them small.

## Decision

- **Shared database, shared schema**; every tenant-owned table has a non-null, indexed
  `agency_id` (denormalized even where derivable).
- **Application scoping:** `Current.agency` is required; tenant models include
  `Tenancy::Scoped`, which applies the scope and raises when no tenant is set.
- **Database enforcement:** PostgreSQL row-level security on every tenant table, keyed on a
  session setting (`app.agency_id`). The app runs as a non-`BYPASSRLS` role; the setting is
  applied per request and per job when a connection is checked out and reset on check-in;
  migrations and platform-level jobs use a separate privileged role.
- CI enforces: tenant table ⇒ `agency_id` + index + RLS policy + isolation tests.

## Consequences

- One schema to migrate; cheap tenants; simple cross-tenant operator metrics.
- Two independent safeguards: a missed scope in Ruby is still blocked by Postgres.
- RLS adds care around connection handling (setting/resetting the session variable) and around
  tooling that needs to bypass it; this must be built and tested in Phase 0.
- Very large tenants can later be moved to their own cell if needed.

## Alternatives considered

- **Schema per tenant** (e.g. apartment-style) — migrations scale with tenant count; tooling is
  poorly maintained; complicates connection pooling.
- **Database per tenant** — strongest isolation, highest ops cost; reserved for an enterprise
  "dedicated cell" offering instead.
- **App scoping only** (e.g. `acts_as_tenant`) — a single forgotten scope leaks data; not
  acceptable as the only line of defence.
