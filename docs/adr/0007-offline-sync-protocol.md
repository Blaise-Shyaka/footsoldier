# ADR-0007: Idempotent, append-only offline sync with device-generated UUIDv7 ids

- Status: Proposed
- Date: 2026-11-06

## Context

Footsoldiers work for hours or days without connectivity on unreliable networks; uploads are
interrupted, retried, duplicated. Reliability is the product's main selling point.

## Decision

- Devices generate **UUIDv7** ids for submissions and attachments.
- Uploads are **`PUT` by id**, idempotent: same id + same SHA-256 → success no-op; same id +
  different checksum → `409`. *Revised:* the server **quarantines** the conflicting payload in
  `submission_conflicts` (visible to agency admins and support, excluded from reporting) and
  replies `409 {quarantined: true}`, so the device may stop retrying without the data existing
  only on the phone. An id that collides with a row the caller cannot see (another tenant's)
  is also `409`, never a phantom `201`.
- Submissions are **append-only**; corrections are separate records. One author per submission,
  so there are no merge conflicts.
- The server **accepts any authenticated submission** for a project the footsoldier was
  assigned to at capture time; validation problems become flags.
- Devices pull changes using a per-agency monotonically increasing **sync cursor**, not
  timestamps. *Revised:* the cursor is the `seq` of an append-only `sync_events` table, and
  `seq` is assigned under a per-agency transaction-scoped advisory lock so events become
  visible in sequence order. Stamping a sequence value on rows at write time is not enough:
  a lower value can commit after a higher one has already been read, and the device would
  skip it forever. Review outcomes and earnings changes travel on the same stream. A device
  with no cursor, or one older than the 90-day event window, gets a snapshot of current state
  plus the current `seq` instead of a replay; older events are pruned.
- *Revised:* a device session belongs to the user; `GET /sync` covers every active
  footsoldier membership and returns one cursor per agency. Footsoldiers borrow each other's
  phones (confirmed 2026-11-09): the app holds one account at a time, and logging out requires
  an empty outbox, so switching accounts never strands the previous user's captures.
- *Revised:* removing a member puts the device session into a **`draining`** state for 30
  days: it may still `PUT` submissions and attachments captured before `revoked_at` (plus
  clock tolerance) and nothing else. Hard revocation is a separate, audited owner action.
- Devices delete nothing until the server acknowledges the submission and every attachment.
- The browser form filler uses the same idempotent create semantics from Phase 1.

Full protocol: [05](../architecture/05-mobile-and-offline-sync.md).

## Consequences

- Retrying is always safe, which makes the client simple and robust.
- The quarantine and draining rules mean no path in the protocol ends with data that exists
  only on a device.
- No conflict-resolution machinery needed in v1.
- Collaborative editing of one record (Phase 4 multi-step records) will need an explicit design
  (separate follow-up records, not concurrent edits to one).

## Alternatives considered

- **Generic sync engines (PowerSync, ElectricSQL, WatermelonDB sync, CouchDB/PouchDB)** — solve
  bidirectional replication we don't need, add a component per cell or a vendor dependency, and
  some don't fit Rails/Postgres-only deployments.
- **Server-generated ids** — needs a round trip before an id exists; breaks offline creation and
  makes duplicates on retry likely.
