# 08 — Deployment and operations

## Regional cells

A **cell** is a complete, independent deployment of Footsoldier for one jurisdiction or
customer group: its own hosts, database, object store, backups and monitoring. Cells share the
codebase and release train, nothing else.

```mermaid
flowchart LR
  subgraph rw["Cell rw (hosted in Rwanda)"]
    rwapp[Rails web + jobs] --> rwpg[(Postgres)]
    rwapp --> rwobj[(Object store)]
  end
  subgraph ke["Cell ke (hosted in Kenya)"]
    keapp[Rails web + jobs] --> kepg[(Postgres)]
    keapp --> keobj[(Object store)]
  end
  subgraph intl["Cell intl (any region)"]
    inapp[Rails web + jobs] --> inpg[(Postgres)]
    inapp --> inobj[(Object store)]
  end
  OPS[Operator overview<br/>aggregate, non-personal metrics only] -.pull.-> rwapp
  OPS -.pull.-> keapp
  OPS -.pull.-> inapp
```

- Hostnames: `<cell>.footsoldier.<tld>` (e.g. `rw.footsoldier.app`); agency custom domains later.
- Kamal config per cell: `config/deploy.yml` (shared) + `config/deploy.<cell>.yml`
  (destination), deployed with `kamal deploy -d <cell>`.
- A future **cell directory** (tiny, personal-data-free service mapping agency slug → cell URL)
  lets users log in from a single domain. Until then invitation links carry the cell URL.

## Runtime components per cell

| Component | Minimum ("small cell") | Recommended ("standard cell") |
|-----------|-------------------------|-------------------------------|
| Rails web (Puma + Thruster) | 1 container | 2 hosts behind Kamal proxy / load balancer |
| Rails jobs (Solid Queue) | same host | 1 dedicated host |
| PostgreSQL | same host, 4 vCPU / 8 GB VM total | Primary + streaming replica on dedicated hosts |
| Object store | Active Storage `Disk` on an attached volume | S3-compatible store (provider's, or self-hosted e.g. Garage / SeaweedFS / Ceph RGW — evaluate maintenance and licensing at selection time) |
| SMTP | In-country relay | Same |
| Monitoring | Same host | Dedicated small host |

The small cell exists so that a pilot in a new country can start on one VM from a local
provider, and grow without architectural change.

## Why Postgres-only

Solid Queue, Solid Cache and Solid Cable put jobs, cache and WebSocket pub/sub in Postgres.
That removes Redis (a component with its own persistence, failover and memory sizing) from
every cell. The trade-off is extra load on Postgres; at our assumed scale
([01](01-context-and-goals.md)) that is comfortable, and queue/cache can be moved to a separate
Postgres database on the same server (Rails supports multiple databases) before anything else
changes.

## Releases and migrations

- One Docker image per commit on `main`, tagged with the git SHA; built in CI.
- Deploy order per cell: staging cell → production cells, one at a time.
- **Zero-downtime migrations** using expand/contract; `strong_migrations` blocks unsafe ones.
  Every migration must be backward compatible with the currently deployed code.
- Feature flags (Flipper, Active Record adapter) separate deploy from release; entitlements
  ([09](09-optional-features.md)) are a separate concept from flags.
- **Mobile releases** are decoupled: the API is versioned (`/api/v1`), additive changes only
  within a version, and the server keeps supporting app versions ≥ `min_app_version` for at
  least 90 days after a new release.

## Backups and recovery

| Item | Approach | Target |
|------|----------|--------|
| Postgres | Continuous WAL archiving + nightly base backups (pgBackRest or WAL-G) to object storage **in the same jurisdiction**, second copy at a different site in-country | RPO ≤ 5 min, RTO ≤ 4 h |
| Object store | Versioning on, replicated or synced to a second site | RPO ≤ 24 h |
| Config / secrets | Kamal secrets in the operator's password manager | — |
| Restore drills | Automated weekly restore of the latest backup into a scratch DB + row-count check; manual full DR drill quarterly | Drill passes |

Devices are part of durability: data stays on the phone until acknowledged
([05](05-mobile-and-offline-sync.md)), so a server-side restore to a point before an upload is
healed by devices re-uploading (idempotent).

## Observability

Everything runs inside the cell so no personal data leaves it.

| Signal | Tooling |
|--------|---------|
| Logs | Rails 8.1 structured event logs (JSON) to stdout → collected on the host (e.g. Vector/Loki) |
| Metrics | Prometheus-format metrics (Yabeda) + Grafana: request latency, error rate, queue latency, sync success rate, upload failures, DB health |
| Errors | Self-hosted, Sentry-protocol-compatible tracker (e.g. GlitchTip) with PII scrubbing; mobile crash reports to the same |
| Uptime | `/up` health check + external probe |
| Business health | Submissions received vs processed, flags rate, devices not synced in > 24 h per agency |

Alerts that page someone: API 5xx rate, job queue latency > 5 min, backup failure, disk > 80 %,
replication lag, `409` checksum conflicts on submissions (should be zero).

## Low-resource operation

- Server-rendered HTML, small JS bundles, compressed responses, long-cached assets.
- Images resized on device before upload; thumbnails generated once in the cell.
- API payloads are small and gzip'd; sync is incremental via cursors.
- Graceful degradation: dashboards still load if WebSockets are blocked (polling fallback).
- Power/connectivity loss on the server side: Postgres synchronous commit on; jobs are
  idempotent and safe to re-run.
