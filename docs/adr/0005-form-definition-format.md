# ADR-0005: Versioned JSON form definitions with immutable published versions

- Status: Proposed
- Date: 2026-11-06

## Context

Every campaign needs different questions; the legacy app needed code for each one. Footsoldiers
may hold an old form version offline for days, so the server must understand submissions made
against older versions, and reports must stay correct as forms evolve.

## Decision

- A form is a JSON document conforming to a JSON Schema (`packages/form-spec`), with a declared
  spec version (`footsoldier.form/1`).
- Forms have versions. Publishing freezes a version (immutable, checksummed); editing creates a
  new draft version. One published version per form at a time.
- Submissions reference the exact `form_version_id` they were captured with.
- Field `key`s are stable across versions and never reused with a different meaning, so
  reporting can aggregate across versions.
- Each published version records `min_app_version`, the oldest mobile app able to render it.

## Consequences

- New campaigns are configuration, not code.
- Historical submissions are always interpretable.
- We own a spec and must evolve it carefully (spec versioning, conformance tests).

## Alternatives considered

- **ODK XForms / XLSForm as the native format** — mature and battle-tested for offline field
  collection, but XML/XPath-based, harder to drive from a visual builder and to evaluate in our
  runtimes. Kept as an import/export target (Phase 4) and a design reference.
- **SurveyJS JSON format** — good builder ecosystem, but couples us to a commercial builder's
  model and licence for the builder UI.
- **Typed tables per form (generated migrations)** — fast queries, but schema changes per form
  publish; operationally fragile.
