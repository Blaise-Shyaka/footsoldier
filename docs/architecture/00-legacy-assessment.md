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
| Deployment | No deployment config in the repo; production DB credentials via env var |

## What it proves

The legacy app is a useful **requirements artefact**. It shows, from real campaigns:

- Forms mix free text, single choice, multi-select (`merchant_has_multiple_acquirers`),
  conditional follow-ups (`why_upi_not_accepted` only when not accepted), and repeated
  blocks (contactless / chip / swipe test scenarios share the same five questions).
- Records sometimes need a **second step by a different role** (BK Arena: agent
  pre-registers a customer; branch admin later issues a card against the record).
- Clients want **percent breakdowns by answer**, **breakdowns by code**, **per-promoter
  performance** and **CSV export**.
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
- **If legacy production data must be preserved**, write a one-off importer that maps each
  legacy table to a generated form definition plus submissions (each legacy column becomes
  a field, each row a submission with `source: legacy_import`). This is a bounded task and
  only worth doing if the data is still needed — to be confirmed by the product owner.

## Legacy requirements to carry into the backlog

| Legacy behaviour | New-platform feature |
|---|---|
| Per-campaign hard-coded forms | Form builder + versioned form definitions |
| `why_*_not_accepted` follow-ups | Conditional visibility (skip logic) |
| contactless/chip/swipe blocks | Field groups, optionally repeatable |
| Card issuance after pre-registration | Multi-stage submissions / follow-up tasks (later phase) |
| Unique ID number | Field-level uniqueness rule within a project → flag duplicates |
| Promoter performance report | Per-footsoldier stats in agency dashboard |
| % breakdown / code breakdown reports | Dashboard widgets over the reporting projection |
| CSV download | Async CSV/XLSX export with field-level PII gating |
| Client sees its campaign only | Client memberships scoped to client projects |
