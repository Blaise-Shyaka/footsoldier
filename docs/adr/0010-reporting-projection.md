# ADR-0010: Typed answer projection for reporting, in Postgres

- Status: Proposed
- Date: 2026-11-06

## Context

Clients expect clear, near-real-time dashboards. Answers are stored as JSONB per submission,
across several form versions. Aggregating directly over JSONB is slow and hard to index for
arbitrary fields; adding a BI/OLAP system would add heavy components to every cell.

## Decision

- After processing, each submission is projected into `submission_values`: one typed row per
  answered field (one per selected option for multi-selects; with `repeat_index` for repeats).
  *Revised:* processing runs when the **answers** are received, not when the last attachment
  arrives; attachment completeness is a flag, so photos trailing on 2G never delay dashboards.
- *Revised:* `submission_values` and `audit_events` are **partitioned by month from the first
  migration**, keyed on server time (`received_at`, `occurred_at`), never device time: a phone
  clock that is years off must not create stray partitions. Widgets support `count`, `sum`,
  `avg`, `min`, `max` over a numeric field, not only counts.
- *Revised:* `submissions` is **not** partitioned. Its primary key on `id` alone is what makes
  `INSERT … ON CONFLICT (id)` idempotent and detects conflicting payloads; Postgres requires a
  partitioned table's unique keys to include the partition key, so partitioning by time would
  allow the same id twice. At the planning peak it holds ~36M rows a year, which one table and
  its indexes handle. If it ever must be split, partition by range of `id` (UUIDv7 ids sort by
  time), which keeps `id` the primary key.
- Dashboards and exports query the projection, always through `Reporting` query objects that
  apply tenant and client-view rules.
- The projection is **derivable**: it can be rebuilt from `submissions` at any time.
- Real-time updates via Turbo Streams over Solid Cable, debounced per project.
- If needed later: per-project daily rollups in Postgres; then a read replica; an embedded BI
  tool (Metabase/Superset) per cell only if clients require ad-hoc analysis.

## Consequences

- Fast, indexable aggregations with plain SQL; no new infrastructure.
- Write amplification (≈ one row per answer). At the planning peak in
  [01](../architecture/01-context-and-goals.md) (100k submissions/day) that is about
  2M rows/day; at the 500k/day ceiling it is 10M rows and ~1 GB per day, which is why
  partitioning is done at creation rather than "if it grows".
- Agency-defined dashboards are limited to the widget types we build.

## Alternatives considered

- **Query JSONB directly** — fine for small projects, degrades quickly; hard to index per field.
- **Embed Metabase/Superset from day one** — powerful, but a JVM/Python service per cell,
  separate permission model to keep in sync with client-view rules, heavier ops.
- **Separate analytics DB (ClickHouse, DuckDB)** — excellent analytics performance; another
  stateful component per cell and replication to manage.
