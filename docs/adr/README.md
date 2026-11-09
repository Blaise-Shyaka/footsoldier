# Architecture Decision Records

Each ADR records one significant decision: context, decision, consequences, and the
alternatives we rejected. ADRs are immutable once *Accepted*; a changed decision gets a new ADR
that *supersedes* the old one.

Statuses: `Proposed` → `Accepted` | `Rejected`; later `Superseded by ADR-NNNN`.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Proposed |
| [0002](0002-rebuild-on-rails-8.md) | Rebuild on Rails 8 instead of upgrading the legacy app | Proposed |
| [0003](0003-modular-monolith.md) | Modular monolith, one per regional cell | Proposed |
| [0004](0004-multi-tenancy.md) | Shared-schema multi-tenancy with app scoping and Postgres RLS | Proposed |
| [0005](0005-form-definition-format.md) | Versioned JSON form definitions with immutable published versions | Proposed |
| [0006](0006-shared-form-logic.md) | JSONLogic for form logic, with a cross-runtime conformance suite | Proposed |
| [0007](0007-offline-sync-protocol.md) | Idempotent, append-only offline sync with device-generated UUIDv7 ids | Proposed |
| [0008](0008-vendor-neutral-regional-cells.md) | Vendor-neutral regional cells on Postgres, deployed with Kamal | Proposed |
| [0009](0009-mobile-stack.md) | React Native (Expo) with SQLite for the mobile app | Proposed |
| [0010](0010-reporting-projection.md) | Typed answer projection for reporting, in Postgres | Proposed |

## Template

```markdown
# ADR-NNNN: <title>

- Status: Proposed
- Date: YYYY-MM-DD
- Deciders: <names>

## Context
## Decision
## Consequences
## Alternatives considered
```
