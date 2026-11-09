# 11 — Roadmap and epics

Phases are ordered by risk and value: first the foundations that are expensive to change later
(tenancy, form format, idempotent submissions), then a usable web product, then offline mobile,
then paid extras. Each epic below becomes a GitHub issue with the `epic` label; stories and
tasks are created under it when the phase starts.

## Phase 0 — Foundations

Goal: an empty but production-grade skeleton deployed to a staging cell.

| Epic | Scope |
|------|-------|
| **E0.0 Legacy hygiene** | *Revised:* rotate the mail credential committed in the legacy `production.rb`; confirm whether `rgdata.rw` still serves the legacy app and whether its data must be migrated |
| **E0.1 Repository reset** | Tag `legacy-v1`; replace legacy app with Rails 8 skeleton (Postgres, Solid trio, Tailwind, esbuild, Minitest); `CLAUDE.md`, issue/PR templates, labels; branch protection |
| **E0.2 CI** | GitHub Actions + `bin/ci`: lint, security, tests; Dependabot |
| **E0.3 Staging cell** | Kamal config, Docker image, staging deploy, backups, `/up`, error tracking, metrics |
| **E0.4 Tenancy core** | `Agency`, `Current`, `Tenancy::Scoped`, RLS helpers (forced RLS, `NULLIF` policies, pool checkout hook, user-keyed pre-tenant policies, composite FKs) + migration generator, isolation test harness with non-owner role and RLS canary, schema lint |
| **E0.5 Identity core** | Users (email or phone, [ADR-0011](../adr/0011-user-identity-email-or-phone.md)), sessions (Rails auth generator), email confirmation, SMS code via `Messaging::SmsProvider`, password reset, rate limiting, `PlatformStaff` login |
| **E0.7 Sync events & partitioning** | *Revised:* `sync_events` with advisory-locked `seq`; monthly partitioning for `submissions`, `submission_values`, `audit_events` — both cheap now and expensive later |
| **E0.6 Audit** | `audit_events`, `Audit.record` API |

## Phase 1 — Web MVP (online capture)

Goal: an agency can run a real campaign end to end in the browser.

| Epic | Scope |
|------|-------|
| **E1.1 Memberships & invitations** | Roles, invitations by email, agency switcher, member management, 2FA for admins |
| **E1.2 Clients & projects** | Client CRUD, project lifecycle, settings, assignments (activate/revoke) |
| **E1.3 Form spec & runtimes** | `form-spec` JSON Schema v1, operator allowlist + custom operators + repeat scoping, conformance vectors, Ruby runtime, TS runtime, publish lints (type change, option values) |
| **E1.4 Form builder** | Draft editing UI, field inspector, live preview, publish/retire, versioning, **choice lists** (agency-owned + platform-provided such as Rwanda admin units, cascading), duplicate form into project |
| **E1.5 Web capture** | Footsoldier project list, form filler (TS runtime), photo resize + upload, GPS capture, idempotent submit, **IndexedDB draft autosave + retry** |
| **E1.6 Submission pipeline** | Ingest service (quarantine on `409`), processing job **on receipt** with `attachments_pending`, quality flags, review queue, review events, **corrections** (kind `correction`, originals kept), `parent_submission_id` in schema |
| **E1.7 Reporting core** | Projection (partitioned), default dashboards, widgets (KPI, breakdown, time series, table) with **count/sum/avg/min/max**, filters, real-time refresh (signal-only broadcasts) |
| **E1.8 Client portal** | Client view config, client dashboards, client-scoped exports (CSV/XLSX) |
| **E1.9 Branding** | Agency and client themes, logos, contrast checks |
| **E1.10 Platform console v1** | Agencies list, onboarding, usage counters, health, support access grants |
| **E1.11 First production cell** | Production deploy in the first jurisdiction, DR drill, runbooks |
| **E1.12 Legacy data import** *(only if confirmed)* | Map legacy tables to forms + submissions |

## Phase 2 — Offline-first mobile

Goal: footsoldiers capture all day without connectivity on low-end Android and iOS.

| Epic | Scope |
|------|-------|
| **E2.1 Device API v1** | Device sessions with `draining` state, `/sync` over `sync_events` with per-agency cursors, form version + choice list fetch, attachments endpoint (`Content-Range`/`HEAD` reserved), per-device rate limits, OpenAPI contract |
| **E2.2 App shell** | Expo app, navigation, i18n, secure login, PIN/biometric unlock, cell URL from invitation |
| **E2.3 Local store & outbox** | SQLite schema + migrations, drafts, outbox state machine |
| **E2.4 Native form renderer** | All v1 field types on top of the shared TS runtime; camera + compression; GPS capture UX |
| **E2.5 Sync engine** | Pull/push per agency, backoff, background sync (best-effort on iOS), attachment upload, min-version handling, draining/revoked handling, TLS-clock error detection, `409` conflicted state |
| **E2.6 Footsoldier self-service** | Submission history with review status, own stats and earnings |
| **E2.7 Mobile quality** | Maestro E2E, chaos tests, device lab, crash reporting, store release pipeline, OTA updates |
| **E2.8 Load & resilience** | k6 load test, sync dashboards and alerts |

## Phase 3 — Paid features

| Epic | Scope |
|------|-------|
| **E3.1 Plans & entitlements** | Plans, subscriptions, entitlement checks, usage limits, upgrade prompts |
| **E3.2 Compensation** | Rates, earnings ledger, statements, payroll export |
| **E3.3 AI form assistant** | Provider adapter, draft generation, suggestions, cost tracking |
| **E3.4 Advanced dashboards** | Custom dashboard builder, maps, cross-field breakdowns, scheduled email reports |
| **E3.5 Billing integration** | Payment provider interface; first provider (incl. mobile money where relevant) |
| **E3.6 Multi-step records** | *Revised, moved from Phase 4:* follow-up forms on a submission by another role, lookup by `respondent_identifier` (legacy BK Arena card issuance); schema already present since E1.6 |

## Phase 4 — Scale and depth

| Epic | Scope |
|------|-------|
| **E4.1 AI insights assistant** | Aggregate-only dashboard explanations |
| **E4.2 Shared-device profiles** | *Revised:* multiple accounts per phone with separate encrypted outboxes |
| **E4.3 Resumable attachment upload** | *Revised:* `Content-Range` + `HEAD` offset, if video or large files appear |
| **E4.4 Cell directory & operator overview** | Single login domain; cross-cell non-personal metrics |
| **E4.5 Form interoperability** | XLSForm import/export; more field types |
| **E4.6 Territories & geofencing** | PostGIS, areas per footsoldier, out-of-area flags |

## Milestone exit criteria

| Milestone | Done when |
|-----------|-----------|
| Phase 0 | Skeleton deployed to staging by CI; isolation harness running with the RLS canary green; cursor-ordering test green; restore drill passed from an off-host backup; legacy credential rotated |
| Phase 1 | One real agency runs one real client campaign; client uses the dashboard unaided |
| Phase 2 | A footsoldier captures a full day offline on a 2 GB Android and syncs with zero loss across chaos tests |
| Phase 3 | At least one agency on a paid plan using compensation or AI |
