# 00 — Legacy assessment

Snapshot of `develop` at `752a5de` (last commit 2022-08-24, 146 commits).

## What exists

| Area | Current state |
|------|---------------|
| Stack | Ruby 3.0.2, Rails 6.1, Webpacker 5, Turbolinks, Tailwind 2 (postcss7-compat), Devise, simple_form, Figaro |
| Data model | One hand-written table per client campaign: `union_pay_merchants`, `union_pay_banks`, `chef_wumujyis` (Engen), `bk_arena_pre_registrations` |
| Roles | Boolean flags on `users` per campaign: `is_promoter`, `works_with_engen`, `is_upi_client`, `bk_arena_admin`, … |
| Authorization | `before_action` checks on those flags in each controller; `after_sign_in_path_for` is an if/else chain over campaigns |
| Reports | Controller methods computing percentages with `Model.where(...).length` over string answers (e.g. `'Approved'`, `'Physical decal'`) |
| Exports | Per-model `to_csv` with hard-coded column lists |
| Tenancy | None. All data in one namespace; any client flag sees all rows of its campaign |
| Tests | Rails scaffold tests only (system tests reference fields that do not match the UI) |
| Deployment | No deployment config in the repo; production DB credentials via env var. *Revised:* `production.rb` names `rgdata.rw` as the mail host, so the app was deployed (it is no longer running, confirmed 2026-11-09); mail went through Gmail (outside the country); **the mail username and password are literal strings in that file, committed 2022-08-11 — rotate them before anything else**. The GitHub repository is public, so the credential has been readable by anyone since then and must be treated as compromised, not just as a hygiene issue |
| Onboarding | *Revised:* anyone can self-register (Devise `:registerable`); roles are then granted by posting a form with a shared `admin_secret_key` from the environment — no record of who granted what |
| Post-capture edits | *Revised:* UnionPay tables carry `edited_by`; the promoter index hides edited rows. Edits were made by promoters (the capturing role) through the same controller, so editing after capture was needed in the first campaign |

## What it proves

The legacy app is a useful **requirements artefact**. It shows, from real campaigns:

- Forms mix free text, single choice, multi-select (`merchant_has_multiple_acquirers`),
  conditional follow-ups (`why_upi_not_accepted` only when not accepted), and repeated
  blocks (contactless / chip / swipe test scenarios share the same five questions).
- Records sometimes need a **second step by a different role** (BK Arena: a promoter
  pre-registers a customer; a user flagged `is_bk_arena_agent` later searches the record by
  ID number or phone and issues a card against it). This was the most recent campaign.
- Clients want **percent breakdowns by answer**, **breakdowns by code**, **per-promoter
  performance**, **sums of a numeric answer per day and per promoter** (Engen `fueled_value`)
  and **CSV export**.
- *Revised:* forms need **shared and cascading option lists**: the BK Arena form has the full
  Rwandan province → district → sector → cell → village hierarchy, and the UnionPay form
  repeats one hard-coded acquirer list in five fields.
- *Revised:* every legacy user has a required phone number (and, as a Devise default, a
  required email); field agents are the primary users. The legacy app does not prove that
  agents lack email, but many field agents in the target market are expected to rely on
  their phone number. The review proposed email-or-phone identity; the product owner chose
  email identity, with a phone number required for footsoldiers ([ADR-0011](../adr/0011-user-identity-is-email.md)).
- Uniqueness rules on an answer matter (unique `id_number`) — i.e. *deduplication* is a
  data-quality feature.
- Personal and sensitive data is collected (national ID numbers, phone numbers, partial
  card numbers).

## What we keep and what we replace

Every campaign being a migration + model + controller + views is precisely what the new
platform's form builder removes. The role model, tenancy model, front-end toolchain
(Webpacker is retired) and Ruby/Rails versions all need replacing. Upgrading in place
would touch every file and still leave us with the wrong core model.

**Decision ([ADR-0002](../adr/0002-rebuild-on-rails-8.md)):** build a new Rails 8 application
in this repository and retire the legacy code.

- Tag the current state as `legacy-v1` and keep the `develop` history intact.
- The first implementation PR replaces the legacy app with a fresh Rails 8 skeleton.
- Keep this document as the record of what the legacy app taught us.
- **No legacy data is migrated or archived** (product owner, 2026-11-09): the legacy app
  holds no data that needs keeping, so there is no importer and no cut-over.

## Legacy requirements to carry into the backlog

| Legacy behaviour | New-platform feature |
|---|---|
| Per-campaign hard-coded forms | Form builder + versioned form definitions |
| `why_*_not_accepted` follow-ups | Conditional visibility (skip logic) |
| contactless/chip/swipe blocks | Field groups, optionally repeatable |
| Card issuance after pre-registration | Follow-up submissions (`parent_submission_id`) — schema in Phase 1, UX in Phase 3 |
| `edited_by` on UnionPay records | Corrections (Phase 1) by reviewers or, if the project allows, by the original footsoldier; originals kept |
| Province/district/sector/cell/village; acquirer lists | Shared, cascading choice lists (Phase 1) |
| Sales per day / per promoter (`sum(fueled_value)`) | Numeric aggregates on widgets |
| Search by ID number or phone | Lookup by `respondent_identifier` fields within a project |
| `admin_secret_key` role grants | Invitations with roles, granted by an identified admin, audited |
| Self-registration | Invitation-only accounts |
| Required phone number on every user | Email identity; phone number required for footsoldiers so they can be reached ([ADR-0011](../adr/0011-user-identity-is-email.md)) |
| Unique ID number | Field-level uniqueness rule within a project → flag duplicates |
| Promoter performance report | Per-footsoldier stats in agency dashboard |
| % breakdown / code breakdown reports | Dashboard widgets over the reporting projection |
| CSV download | Async CSV/XLSX export with field-level PII gating |
| Client sees its campaign only | Client memberships scoped to client projects |
