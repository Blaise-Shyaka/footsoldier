# ADR-0011: User identity is an email address

- Status: Accepted
- Date: 2026-11-09
- Deciders: Blaise Shyaka (product owner)

## Context

Every person on the platform has one identity per cell. Invitations, memberships, device
sessions and audit events all reference it, so the identity key is expensive to change after
Phase 0. The architecture review ([F7](../review-findings.md)) proposed email *or* phone as
the identifier, with SMS invitations, because field agents are the most numerous users and
some may rely on a phone number rather than an email address. The legacy app required both an
email and a phone number from every user.

## Decision

- **Email is the identity.** `User.email` (citext, unique, required) is the login identifier.
  Invitations, confirmation and password reset all go by email link.
- **A phone number is required for footsoldiers**, because the agency needs a way to reach
  its field agents; for everyone else it is optional. `User.phone` is nullable in the
  database; the requirement is checked when a footsoldier membership is created or activated
  (invitation acceptance, or a role change to footsoldier), which asks for a number if the
  user has none. Numbers are stored in E.164 and are not unique (relatives or colleagues may
  share one). They are **validated without SMS** using libphonenumber (`phonelib` on the
  server, `libphonenumber-js` in the web and mobile forms): the right number of digits and a
  real prefix for the country, with each cell setting a default country so local numbers can
  be typed, and footsoldier numbers must be mobile numbers. This proves a number is well
  formed, not that it exists or belongs to the person. It is not a login identifier.
- **Phone as a second factor is possible later, not in v1.** An SMS code could serve as the
  second factor for users without an authenticator app, such as footsoldiers. It would need an
  SMS provider per cell (in-country where residency requires it) and a verified phone number.
  SMS codes are weaker than TOTP (SIM swap), so TOTP stays the required factor for owners and
  admins either way.

## Consequences

- One login path and one verified contact channel; no cell needs an SMS provider in v1.
- Every footsoldier needs a working email address to accept an invitation. Agencies whose
  agents have none must help them create one, and onboarding guidance should say so.
- Every footsoldier gives a phone number (when accepting an invitation), as the legacy app
  required of every user.
- Phone numbers are personal data on `users`, classified as PII for logs and exports.
- Adding phone login later would mean verifying and de-duplicating stored numbers before
  making them unique, then adding an SMS invitation path. Existing accounts keep their email
  identity, so no existing record changes meaning.

## Alternatives considered

- **Email or phone, with SMS invitations** (the review's proposal) — onboards agents without
  email, but adds a per-cell SMS provider, phone-only password reset and a second identity
  path to the first two phases.
- **Phone only** — breaks agency and client staff workflows built around email and ties every
  cell to an SMS provider from day one.
- **Username and password set by the agency** — no verified contact channel; password reset
  becomes a manual support task.
