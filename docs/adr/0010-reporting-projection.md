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
- Dashboards and exports query the projection, always through `Reporting` query objects that
  apply tenant and client-view rules.
- The projection is **derivable**: it can be rebuilt from `submissions` at any time.
- Real-time updates via Turbo Streams over Solid Cable, debounced per project.
- If needed later: per-project daily rollups in Postgres; then a read replica; an embedded BI
  tool (Metabase/Superset) per cell only if clients require ad-hoc analysis.

## Consequences

- Fast, indexable aggregations with plain SQL; no new infrastructure.
- Write amplification (≈ one row per answer) — acceptable at assumed volumes; partition by
  month if it grows.
- Agency-defined dashboards are limited to the widget types we build.

## Alternatives considered

- **Query JSONB directly** — fine for small projects, degrades quickly; hard to index per field.
- **Embed Metabase/Superset from day one** — powerful, but a JVM/Python service per cell,
  separate permission model to keep in sync with client-view rules, heavier ops.
- **Separate analytics DB (ClickHouse, DuckDB)** — excellent analytics performance; another
  stateful component per cell and replication to manage.
