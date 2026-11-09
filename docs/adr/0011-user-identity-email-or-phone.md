# ADR-0011: User identity is an email address or a phone number

- Status: Proposed
- Date: 2026-11-07

## Context

Footsoldiers are the platform's most numerous users and the ones most likely to have a phone
number but no email address. The legacy app required a phone number for every user and
routed field agents first after login ([00](../architecture/00-legacy-assessment.md)).
The identity key is referenced by invitations, device sessions, memberships and audit events,
so changing it after Phase 0 is a migration across every module. The brief says invitations go
by email; the README's open question 4 asks whether phone + SMS should also be supported.

## Decision

- `User` has `email` (citext) and `phone` (E.164), both nullable, each unique when present,
  at least one required. Login accepts either.
- Invitations are sent by email link or by SMS code; the inviter chooses per invitee. A
  membership can therefore be created for a phone-only person.
- SMS is sent through an **SMS provider configured per cell** (in-country where residency
  requires it), behind a `Messaging::SmsProvider` interface, with a "no SMS provider"
  fallback that shows the inviter a shareable invitation link instead.
- Password reset works through whichever identifier the account has; phone-only accounts
  reset by SMS code.
- TOTP 2FA for owners/admins is unchanged; SMS is never used as a second factor.

## Consequences

- Field agents without email can be onboarded; agencies are not forced to create emails for
  them.
- One more per-cell integration (SMS provider) and its cost; the fallback keeps the platform
  usable without it.
- Phone numbers are personal data on `users` and are classified as PII for logs and exports.

## Alternatives considered

- **Email only** (the v0.1 proposal) — simplest, excludes a large share of the target users or
  pushes agencies into creating throwaway emails that nobody can recover.
- **Phone only** — excludes agency and client staff workflows built around email and ties
  every cell to an SMS provider from day one.
- **Username + password set by the agency** — works offline-ish, but makes password reset a
  manual support process and provides no verified contact channel.
