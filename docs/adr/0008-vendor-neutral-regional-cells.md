# ADR-0008: Vendor-neutral regional cells on Postgres, deployed with Kamal

- Status: Proposed
- Date: 2026-11-06

## Context

Some jurisdictions require personal data to stay in-country. For example, Rwanda's Law
No. 058/2021 (Art. 50) requires personal data to be stored in Rwanda unless authorised by the
National Cyber Security Authority. In-country hosting options are often plain VMs from local
providers, not a hyperscaler's managed services. Operations staff are few.

## Decision

- Deploy the platform as independent **cells**, one per jurisdiction (or dedicated customer),
  each with its own database, object store, backups, logs and monitoring hosted in that
  jurisdiction.
- Allowed runtime dependencies per cell: **PostgreSQL**, an **S3-compatible object store** (or
  local disk for the smallest cell), an **SMTP relay**. Jobs, cache and WebSockets use Rails'
  Solid Queue / Solid Cache / Solid Cable on Postgres. No Redis, no managed queues.
- Package as Docker images and deploy with **Kamal** to any Linux host over SSH.
- Nothing personal crosses cells; any central operator view receives aggregate metrics only.
- *Revised (2026-11-09):* a **demo environment**, which is not a cell and holds no real
  campaign data, runs on the team's Coolify server. Production cells use Kamal, and the Kamal
  path is proven on a throwaway VM before any client signs
  ([08](../architecture/08-deployment-and-operations.md#environments)).

## Consequences

- A new country = a new cell from configuration; no code changes.
- We operate Postgres ourselves (backups, replication, upgrades) — offset by fewer components.
  *Revised:* failover to the replica is **manual** (a runbook, inside the 4 h RTO); automatic
  failover would need a consensus component we deliberately do not run.
- *Revised:* even the smallest cell, where the object store is local disk on the same VM,
  must ship backups to a **second host or an in-country bucket**. A backup on the database's
  own disk is not a backup.
- Postgres carries extra load from queue/cache; can be split into a separate database on the
  same server first, then a separate server, before introducing any new technology.
- Users of multiple cells need separate logins until a cell directory exists (Phase 4).

## Alternatives considered

- **Single global deployment** — violates residency requirements.
- **Kubernetes** — portable, but heavy to run well for a small team on a few VMs; Kamal covers
  our needs. Revisit if a customer mandates it.
- **Cloud-managed services (RDS, SQS, ElastiCache)** — ties cells to one vendor and excludes
  in-country hosting.
