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
- *Revised — mechanism details, each of which is a silent failure if omitted:*
  - Policies read the setting as `NULLIF(current_setting('app.agency_id', true), '')::bigint`.
    The plain form raises an error when the setting is absent instead of returning no rows.
  - Every tenant table has `FORCE ROW LEVEL SECURITY`. Table owners bypass RLS otherwise, and
    the Rails test database is owned by the test role, so isolation tests would pass with RLS
    doing nothing. Tests run as a role that is neither the owner nor a **superuser**:
    superusers bypass RLS even when it is forced, and many local Postgres installs connect as
    one by default.
  - The setting is applied in a **connection-pool checkout hook** driven by `Current`, not by
    request middleware alone: since Rails 7.2 a request can check out more than one connection,
    and any connection without the setting returns zero rows. `load_async` stays **disabled in
    v1**: it runs queries on executor threads where `Current` is not set, so the hook cannot
    see the tenant there.
  - **No transaction-mode pooler** (PgBouncer in transaction mode) in front of the app role:
    session `SET` would leak between clients. If one is ever needed, switch to `SET LOCAL`
    inside an explicit transaction per request.
  - Queries that legitimately run **before a tenant is chosen** (a user's own memberships for
    the agency switcher, device login) get explicit user-keyed policies
    (`user_id = NULLIF(current_setting('app.user_id', true), '')::bigint`), never `BYPASSRLS`.
    **Invitation acceptance** cannot use them, because the invitee may have no account yet; it
    goes through one narrow `SECURITY DEFINER` function that takes a token digest and returns
    at most that one invitation.
  - **Composite foreign keys** on child tables, e.g.
    `(agency_id, project_id) REFERENCES projects (agency_id, id)`, so a denormalized
    `agency_id` can never disagree with its parent row.
  - **Support access grants** run through the normal RLS role with `app.agency_id` set to the
    granted agency, so support reads keep both safeguards.
- CI enforces: tenant table ⇒ `agency_id` + index + RLS policy (forced) + composite FK to its
  parent + isolation tests.

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
