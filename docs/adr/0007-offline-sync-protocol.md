# ADR-0007: Idempotent, append-only offline sync with device-generated UUIDv7 ids

- Status: Proposed
- Date: 2026-11-06

## Context

Footsoldiers work for hours or days without connectivity on unreliable networks; uploads are
interrupted, retried, duplicated. Reliability is the product's main selling point.

## Decision

- Devices generate **UUIDv7** ids for submissions and attachments.
- Uploads are **`PUT` by id**, idempotent: same id + same SHA-256 → success no-op; same id +
  different checksum → `409`, alert, device keeps data.
- Submissions are **append-only**; corrections are separate records. One author per submission,
  so there are no merge conflicts.
- The server **accepts any authenticated submission** for a project the footsoldier was
  assigned to at capture time; validation problems become flags.
- Devices pull changes using a per-agency monotonically increasing **sync cursor**, not
  timestamps.
- Devices delete nothing until the server acknowledges the submission and every attachment.
- The browser form filler uses the same idempotent create semantics from Phase 1.

Full protocol: [05](../architecture/05-mobile-and-offline-sync.md).

## Consequences

- Retrying is always safe, which makes the client simple and robust.
- No conflict-resolution machinery needed in v1.
- Collaborative editing of one record (Phase 4 multi-step records) will need an explicit design
  (separate follow-up records, not concurrent edits to one).

## Alternatives considered

- **Generic sync engines (PowerSync, ElectricSQL, WatermelonDB sync, CouchDB/PouchDB)** — solve
  bidirectional replication we don't need, add a component per cell or a vendor dependency, and
  some don't fit Rails/Postgres-only deployments.
- **Server-generated ids** — needs a round trip before an id exists; breaks offline creation and
  makes duplicates on retry likely.
