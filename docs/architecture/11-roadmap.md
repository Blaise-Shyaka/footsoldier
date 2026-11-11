# 11 — Roadmap and epics

Phases are ordered by risk and value: first the foundations that are expensive to change later
(tenancy, form format, idempotent submissions), then a usable web product, then offline mobile,
then paid extras. Each epic below becomes a GitHub issue with the `type:epic` label; its
stories, and their tasks, are created as sub-issues when the phase starts
([12](12-delivery-workflow.md#issues)).

## Phase 0 — Foundations

Goal: an empty but production-grade skeleton deployed to the demo environment on Coolify.

| Epic | Scope |
|------|-------|
| **E0.0 Legacy hygiene** | *Revised:* revoke the Gmail app password committed in the legacy `production.rb` (**done 2026-11-09**; public repository: treat as compromised, check the mailbox for IMAP access, forwarding and filters); turn on GitHub secret scanning and push protection; the legacy deployment at `rgdata.rw` is no longer running (confirmed 2026-11-09) |
| **E0.1 Repository reset** | `legacy-v1` tagged on `752a5de` (done 2026-11-09); `main` is the default branch (fast-forwarded to `develop` on 2026-11-09); protect `main`; delete `develop` and stale branches ([12](12-delivery-workflow.md)); replace legacy app with Rails 8 skeleton (Postgres, Solid trio, Tailwind, esbuild, Minitest); `CLAUDE.md`, issue/PR templates, labels; branch protection |
| **E0.2 CI** | GitHub Actions + `bin/ci`: lint, security (including a secret scan with gitleaks over the diff, and over full history once), tests; Dependabot |
| **E0.3 Demo environment** | Docker image built by CI and pushed to GitHub's registry; Coolify app with deploy webhook; Coolify Postgres with a restricted app role and the four Rails databases; Garage for files; dumps and Garage copies to an off-server bucket; `/up`, error tracking, metrics; no real campaign data ([08](08-deployment-and-operations.md#environments)) |
| **E0.4 Tenancy core** | `Agency`, `Current`, `Tenancy::Scoped`, RLS helpers (forced RLS, `NULLIF` policies, pool checkout hook, user-keyed pre-tenant policies, invitation lookup function, composite FKs) + migration generator, isolation test harness with a non-owner, non-superuser role and RLS canary, schema lint |
| **E0.5 Identity core** | Users (email identity; phone number required for footsoldiers, validated with libphonenumber; [ADR-0011](../adr/0011-user-identity-is-email.md)), sessions (Rails auth generator), email confirmation, password reset, rate limiting, `PlatformStaff` login |
| **E0.6 Audit** | `audit_events`, `Audit.record` API |
| **E0.7 Sync events & partitioning** | *Revised:* `sync_events` with advisory-locked `seq`; monthly partitioning on server time for `submission_values` and `audit_events` — both cheap now and expensive later |
| **E0.8 Kamal dry run** | Kamal configuration for production cells; deploy the same image to a throwaway VM; continuous WAL archiving off the host; restore on a separate host; record findings; delete the VM. At the end of Phase 0 if capacity allows, and in any case **before any client signs** ([08](08-deployment-and-operations.md#kamal-dry-run)) |

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
| **E1.11 First production cell** | When the first client signs: Linux servers in the client's jurisdiction, deployed with Kamal (E0.8 passed), WAL backups off the host, DR drill, runbooks |

## Phase 2 — Offline-first mobile

Goal: footsoldiers capture all day without connectivity on low-end Android and iOS.

| Epic | Scope |
|------|-------|
| **E2.1 Device API v1** | Device sessions with `draining` state, `/sync` over `sync_events` with per-agency cursors, form version + choice list fetch, attachments endpoint (`Content-Range`/`HEAD` reserved), per-device rate limits, OpenAPI contract |
| **E2.2 App shell** | Expo app, navigation, i18n, secure login, PIN/biometric unlock, logout only with an empty outbox (borrowed phones), cell URL from invitation |
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
| **E4.2 Resumable attachment upload** | *Revised:* `Content-Range` + `HEAD` offset, if video or large files appear |
| **E4.3 Cell directory & operator overview** | Single login domain; cross-cell non-personal metrics |
| **E4.4 Form interoperability** | XLSForm import/export; more field types |
| **E4.5 Territories & geofencing** | PostGIS, areas per footsoldier, out-of-area flags |

## Milestone exit criteria

| Milestone | Done when |
|-----------|-----------|
| Phase 0 | Skeleton deployed to the Coolify demo by CI; isolation harness running with the RLS canary green; cursor-ordering test green; restore test passed from the demo's off-server backup; legacy Gmail app password revoked; secret scanning and push protection on |
| Before any client signs | Kamal dry run (E0.8) passed, including a restore from WAL backups |
| Phase 1 | One real agency runs one real client campaign on a production cell; client uses the dashboard unaided |
| Phase 2 | A footsoldier captures a full day offline on a 2 GB Android and syncs with zero loss across chaos tests; switching a phone to another footsoldier's account loses none of the first footsoldier's captures |
| Phase 3 | At least one agency on a paid plan using compensation or AI |
