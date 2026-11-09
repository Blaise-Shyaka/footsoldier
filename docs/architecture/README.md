# Footsoldier — Architecture

Status: **Proposed** (v0.1, 2026-11-06). Nothing here is final until the decisions in
[`docs/adr`](../adr) are marked *Accepted*.

Footsoldier is a multi-tenant SaaS for field data collection. Agencies design forms,
recruit and assign field agents ("footsoldiers"), and present the collected data to the
clients who commissioned the research. The single most important quality is
**reliability**: data captured in the field must never be lost, duplicated or silently
altered, and the platform must run in low-resource environments under national
data-residency rules.

## How to read this

| # | Document | Answers |
|---|----------|---------|
| 00 | [Legacy assessment](00-legacy-assessment.md) | What exists today and what we keep |
| 01 | [Context, goals and constraints](01-context-and-goals.md) | Who uses it, what "good" means, what limits us |
| 02 | [System overview](02-system-overview.md) | Containers, modules, repo layout, tech stack |
| 03 | [Domain model and access control](03-domain-model.md) | Entities, tenancy, roles, permissions |
| 04 | [Forms and submissions](04-forms-and-submissions.md) | Form definition format, versioning, logic, GPS, media, review |
| 05 | [Mobile app and offline sync](05-mobile-and-offline-sync.md) | Offline-first app, sync protocol, API |
| 06 | [Reporting, dashboards and branding](06-reporting-and-branding.md) | Analytics model, client view, real-time, exports, themes |
| 07 | [Security, privacy and data residency](07-security-privacy-residency.md) | Tenant isolation, auth, PII, platform oversight, audit |
| 08 | [Deployment and operations](08-deployment-and-operations.md) | Regional cells, infrastructure, backups, observability |
| 09 | [Optional and paid features](09-optional-features.md) | Plans/entitlements, compensation, AI assistants |
| 10 | [Testing strategy](10-testing-strategy.md) | Test layers, conformance suites, CI |
| 11 | [Roadmap and epics](11-roadmap.md) | Phases and the epics that become GitHub issues |
| 12 | [Delivery workflow (proposal)](12-delivery-workflow.md) | Branches, commits, issues, PRs, agent notes |

Architecture Decision Records live in [`docs/adr`](../adr/README.md).

## The architecture on one page

- **One Rails 8 modular monolith per region** ("cell"). Web UI (Hotwire), JSON API for the
  mobile app, background jobs and real-time updates all run from the same codebase.
  No microservices. ([ADR-0003](../adr/0003-modular-monolith.md))
- **PostgreSQL is the only stateful dependency** besides an S3-compatible object store and
  an SMTP relay. Jobs, cache and WebSockets use the Rails 8 "Solid" adapters on Postgres,
  so there is no Redis to run. ([ADR-0008](../adr/0008-vendor-neutral-regional-cells.md))
- **The agency is the tenant.** Every tenant-owned row carries `agency_id`; isolation is
  enforced in the application *and* by PostgreSQL row-level security.
  ([ADR-0004](../adr/0004-multi-tenancy.md))
- **Forms are data, not code.** A form is a versioned JSON document; published versions
  are immutable; submissions always point at the exact version they were captured with.
  ([ADR-0005](../adr/0005-form-definition-format.md))
- **The same form logic runs everywhere.** Skip logic, validation and calculations use
  JSONLogic, with a shared conformance test suite run against the Ruby (server) and
  TypeScript (web + mobile) implementations. ([ADR-0006](../adr/0006-shared-form-logic.md))
- **Sync is idempotent and append-only.** Devices create submissions with their own
  UUIDv7 ids; uploads can be retried any number of times; the server never rejects field
  data it can authenticate — it accepts and flags it.
  ([ADR-0007](../adr/0007-offline-sync-protocol.md))
- **Mobile is React Native (Expo) with SQLite**, offline-first, built after the web MVP
  but against the same API the web form filler already uses.
  ([ADR-0009](../adr/0009-mobile-stack.md))
- **Analytics read from a typed projection** of submission answers, refreshed by jobs and
  pushed to dashboards over Turbo Streams. The agency decides exactly what the client sees.
  ([ADR-0010](../adr/0010-reporting-projection.md))
- **Deployable anywhere with Kamal** onto plain Linux hosts, one cell per jurisdiction
  (e.g. a Rwanda cell hosted in Rwanda). ([ADR-0008](../adr/0008-vendor-neutral-regional-cells.md))

## Open questions for the product owner

These change scope or sequencing; see each linked document for the trade-offs.

1. Is there production data in the legacy app that must be migrated, or only archived?
   ([00](00-legacy-assessment.md))
2. Can one real-world client be served by two agencies on the platform, and does the client
   then expect a single combined login? The proposal says *separate client records per
   agency, one user identity*. ([03](03-domain-model.md))
3. Mobile stack: React Native is proposed mainly to share TypeScript form logic with the
   web. If the team has stronger Flutter/Dart skills, revisit [ADR-0009](../adr/0009-mobile-stack.md).
4. Should footsoldiers be able to log in with phone number + SMS code as well as email?
   The brief says email invitations; many field agents may use phone numbers primarily.
5. Branching: `develop` is the current default and `main` is stale. Proposal: single trunk
   `main`. ([12](12-delivery-workflow.md))
