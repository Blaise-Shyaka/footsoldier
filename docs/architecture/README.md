# Footsoldier — Architecture

Status: **Proposed** (v0.3, 2026-11-09). Nothing here is final until the decisions in
[`docs/adr`](../adr) are marked *Accepted*; ADR-0009 and ADR-0011 are.

> **v0.3** records the product owner's answers to the open questions
> ([below](#product-owner-decisions-2026-11-09)).

> **v0.2** applies the findings in [`docs/review-findings.md`](../review-findings.md).
> Paragraphs that changed are marked *Revised*. The main changes: a gap-free sync cursor,
> processing on receipt instead of after attachments, quarantine for checksum conflicts,
> draining device sessions for removed members, a realistic sizing assumption with
> partitioning from day one, the concrete RLS mechanism, and corrections, choice lists and
> numeric aggregates pulled forward into Phase 1. (v0.2 also proposed email-or-phone
> identity; v0.3 replaces it with email identity,
> [ADR-0011](../adr/0011-user-identity-is-email.md).)
>
> Where the review's own fixes needed correcting (for example, partitioning `submissions`
> would have broken idempotent uploads), the change is described in the
> [response to the review](../review-findings.md#response-to-the-review).

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
  data it can authenticate — it accepts and flags it, quarantines what conflicts, and keeps
  accepting from removed members until their outbox has drained.
  ([ADR-0007](../adr/0007-offline-sync-protocol.md))
- **Mobile is React Native (Expo) with SQLite**, offline-first, built after the web MVP
  but against the same API the web form filler already uses.
  ([ADR-0009](../adr/0009-mobile-stack.md))
- **Analytics read from a typed projection** of submission answers, refreshed by jobs and
  pushed to dashboards over Turbo Streams. The agency decides exactly what the client sees.
  ([ADR-0010](../adr/0010-reporting-projection.md))
- **Deployable anywhere with Kamal** onto plain Linux hosts, one cell per jurisdiction
  (e.g. a Rwanda cell hosted in Rwanda). A demo with no real campaign data runs on the team's
  Coolify server. ([ADR-0008](../adr/0008-vendor-neutral-regional-cells.md),
  [08](08-deployment-and-operations.md#environments))

## Product-owner decisions (2026-11-09)

| # | Question | Decision | Where it lands |
|---|----------|----------|----------------|
| 1 | Must legacy production data be migrated or archived? | **Neither.** The legacy app holds no data worth keeping; no importer, no cut-over. | [00](00-legacy-assessment.md), [ADR-0002](../adr/0002-rebuild-on-rails-8.md), [11](11-roadmap.md) |
| 2 | Can one real-world client be served by several agencies? | **Yes, but its data is never combined.** One `Client` record per agency; a client person has one user identity and a membership in each agency, and switches between them. | [03](03-domain-model.md) |
| 3 | Mobile stack | **React Native (Expo).** | [ADR-0009](../adr/0009-mobile-stack.md), accepted |
| 4 | Log in with phone as well as email? | **No: email is the identity.** A phone number is required for footsoldiers so they can be reached (optional for others, validated without SMS); it is not a login, and may later serve as a second factor. This overrules the review's email-or-phone proposal. | [ADR-0011](../adr/0011-user-identity-is-email.md), accepted |
| 5 | Branching | **Single trunk `main`.** Done 2026-11-09: `main` was fast-forwarded to `develop` and is the default branch. `develop` is deleted in E0.1. | [12](12-delivery-workflow.md), [11](11-roadmap.md) E0.1 |
| 6 | Do footsoldiers work for several agencies, and do they share phones? | **Yes to both.** Multi-agency support stays as designed. A borrower logs in with their own details; the app holds one account at a time, and logout waits until the outbox has synced. No multi-profile support is planned. | [05](05-mobile-and-offline-sync.md) |
| 7 | Where does it run? | **Demo on the team's Coolify server** (full flow, no real campaign data). **Production on Linux servers in the client's country with Kamal**, from the first signed client. The Kamal path is proven on a throwaway VM at the end of Phase 0 if capacity allows, and before any client signs. No Cloudflare edge services. | [08](08-deployment-and-operations.md#environments), [11](11-roadmap.md) |

## Open questions for the product owner

None at the moment. The last one closed on 2026-11-09: the leaked Gmail app password is
revoked and `rgdata.rw` is no longer running ([00](00-legacy-assessment.md)).
