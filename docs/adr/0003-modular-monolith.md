# ADR-0003: Modular monolith, one per regional cell

- Status: Proposed
- Date: 2026-11-06

## Context

Requirements stress reliability and "no unnecessary complexity", deployment by a small team in
low-resource environments, and multiple independent regional deployments. Microservices would
multiply deployable units, network failure modes and operational cost per cell.

## Decision

Build one Rails application containing web UI, device API and background jobs, organised into
namespaced modules with one-way dependencies ([02](../architecture/02-system-overview.md)).
Deploy it as two process roles (web, jobs) from one image. The mobile app and the shared
TypeScript form runtime live in the same repository (monorepo).

## Consequences

- One deploy, one database, transactional consistency across modules.
- Module boundaries depend on discipline; add packwerk if they erode.
- Scaling is vertical plus more web/job containers — sufficient for the assumed load.

## Alternatives considered

- **Microservices (forms, submissions, reporting…)** — distributed transactions and N× ops
  burden per cell; not justified at our scale.
- **Separate API app + SPA frontend** — two codebases, more JS to maintain, slower on low-end
  devices than server-rendered Hotwire.
