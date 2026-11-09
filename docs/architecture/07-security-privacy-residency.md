# 07 — Security, privacy and data residency

## Tenant isolation (defence in depth)

A cross-tenant leak would end the product, so isolation is enforced twice
([ADR-0004](../adr/0004-multi-tenancy.md)):

1. **Application layer.** Tenant models include `Tenancy::Scoped`, which requires
   `Current.agency` and applies `where(agency_id: Current.agency.id)`. Accessing a tenant model
   without a tenant context raises (except in explicitly marked platform/maintenance code).
2. **Database layer.** PostgreSQL row-level security policies on every tenant table.
   *Revised* — the mechanism, because each omission is a silent failure
   ([ADR-0004](../adr/0004-multi-tenancy.md)):
   - Policy: `USING (agency_id = NULLIF(current_setting('app.agency_id', true), '')::bigint)`.
     The plain `current_setting(...)::bigint` raises when the setting is absent instead of
     returning no rows.
   - `ALTER TABLE … FORCE ROW LEVEL SECURITY` on every tenant table. Owners bypass RLS
     otherwise, and the test database is owned by the test role, so isolation tests would
     pass vacuously. Tests connect as a non-owner role.
   - The setting is applied in a **connection-pool checkout hook** from `Current` and
     cleared on check-in; any connection without it sees no rows (fail closed). `load_async`
     and any second connection in a request are covered by the same hook, and `load_async`
     stays disabled until it is.
   - **No transaction-mode pooler** in front of the app role (session `SET` would leak between
     clients); if ever needed, switch to `SET LOCAL` per request transaction.
   - Pre-tenant queries (a user's memberships for the agency switcher, invitation lookup,
     device login) use **user-keyed policies** on `app.user_id`, never `BYPASSRLS`.
   - Composite foreign keys `(agency_id, parent_id)` keep the denormalized `agency_id`
     consistent with the parent row.
   Migrations and platform-level maintenance use a separate role with `BYPASSRLS`; support
   access grants do **not** — they run as the normal role with `app.agency_id` set to the
   granted agency, so both safeguards stay on.

A **tenant isolation test suite** creates two agencies and asserts, for every tenant model and
every API/HTML endpoint, that agency B's data is unreachable with agency A's context
([10](10-testing-strategy.md)). New tenant tables fail CI unless they have `agency_id`, an index
on it, and an RLS policy (checked by a schema lint test).

## Authentication

| Who | Mechanism |
|-----|-----------|
| Agency & client users (web) | Rails 8 authentication generator (`has_secure_password`, DB-backed sessions), email confirmation, password reset, rate limiting on login. TOTP 2FA required for `agency_owner`/`agency_admin`, optional for others. |
| Footsoldiers (web) | Same as above; invited by email link **or SMS code** ([ADR-0011](../adr/0011-user-identity-email-or-phone.md)); phone-only accounts reset passwords by SMS code. |
| Footsoldiers (mobile) | Device token (256-bit random, stored as SHA-256 digest) bound to `device_id`; revocable per device; local PIN/biometric to unlock offline. *Revised:* states `active` → `draining` → `revoked`; a draining token can only upload captures made before removal, for 30 days. |
| Platform staff | Separate `PlatformStaff` model and login path, mandatory 2FA, IP allowlist optional. |

Web sessions are revoked when a membership is removed or a password changed. *Revised:*
device sessions are put into `draining` on membership removal so the outbox can finish
([05](05-mobile-and-offline-sync.md)); a password change or an explicit owner action
hard-revokes them.

## Authorization

Pundit policies per resource, with the three layers in [03](03-domain-model.md): tenant
context, role, resource scope. Policy tests are mandatory for every policy.

## Personal data handling

- **Classification at field level** (`pii`, `sensitive`) in the form definition.
  - PII fields are hidden from client views and exports unless the agency explicitly enables them.
  - `sensitive` fields (national ID, health, financial) additionally require an extra
    confirmation to export and are masked in tables by default (`••••1234`).
- **Encryption.** TLS everywhere; encrypted volumes for Postgres and object storage; encrypted
  backups. Active Record Encryption for secrets we hold (TOTP secrets, API keys, provider
  tokens). Answer JSONB is not app-encrypted in v1 (it must be queryable); revisit if a client
  requires it.
- **Retention.** `retention_days` per project; a scheduled job purges submissions, attachments
  and projection rows past retention after project close, with an audit event.
- **Data subject requests.** Fields marked `respondent_identifier` (e.g. phone, national ID) let
  an agency find and export/delete a respondent's records.
- **Logs and error reports never contain answer content.** Parameter filtering covers
  `answers`, `password`, tokens, and any field marked PII; error tracking runs inside the cell.
- **Breach readiness.** Audit log + access logs make it possible to establish scope quickly;
  the incident runbook includes regulator notification timelines per jurisdiction.
- *Revised — compliance checklist per cell.* For Rwanda, Law No. 058/2021 also expects data
  controllers (agencies) and processors (the platform operator) to register with the NCSA and,
  depending on scale, to designate a data protection officer; confirm the exact obligations
  with counsel before the first production cell and record them in the cell runbook.
- *Revised — legacy hygiene.* The legacy repository's production config contains a literal
  mail credential (committed 2022-08-11) and the legacy app relayed mail through Gmail.
  Rotate that credential before the repository reset; git history keeps it forever.

## Data residency

- **One cell per jurisdiction that requires it.** A cell has its own database, object store,
  backups, logs and error tracking, all hosted in that jurisdiction
  ([ADR-0008](../adr/0008-vendor-neutral-regional-cells.md)).
- An agency is created in exactly one cell (`agency.data_region`) and its data never leaves it.
- Anything crossing the cell boundary must contain **no personal data**: e.g. aggregate usage
  counters to a central operator overview, app crash reports scrubbed of PII.
- **Third-party processors** (email relay, AI provider) are configured per cell. For a cell
  where sending data abroad needs authorisation (e.g. Rwanda), the defaults are an in-country
  SMTP relay and AI features limited to inputs with no personal data (form drafting from a
  project description) unless an approved provider is configured.

## Platform oversight without intrusion

The operator console shows **metadata, never content**:

- agencies, plans, status, member counts, storage used, submission counts per day,
- health: sync error rates, job queue latency, failed uploads, app versions in the field,
- billing state.

Reading tenant content requires a **support access grant**: an agency owner grants a named
staff member time-boxed (e.g. 24 h), read-only access, optionally limited to one project. Every
access under a grant is audited and visible to the agency.

## Audit log

`audit_events` (append-only; no UPDATE/DELETE grant for the app role): `agency_id`, actor
(user / platform staff / system), action, subject type/id, metadata (no PII values), IP, user
agent, `occurred_at`. Recorded for: membership and role changes, assignment changes, form
publication, review decisions, client-view changes, exports, deletions, support access,
login/2FA events.

## Application security baseline

- Brakeman, `bundler-audit`, `npm audit` in CI; Dependabot for Ruby, JS and GitHub Actions.
- Rails 8 `rate_limit` on auth endpoints and the device API. *Revised:* limits on
  authentication and `GET` endpoints are strict; `PUT` submissions and attachments are limited
  **per device** at a rate far above any honest outbox (e.g. 600/min) and only alert below an
  abuse threshold, so a footsoldier draining a day's work is never blocked.
- Strict CSP; signed and expiring URLs for every file; no public buckets.
- Uploaded files: content-type sniffing, size limits, image re-encoding (strips payloads).
- Secrets via Kamal secrets / environment, never in the repo; `config/master.key` per cell.
