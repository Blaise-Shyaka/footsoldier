# Architecture review — findings

Reviewer: Claude Fable 5.1, 2026-11-07. Reviewed `docs/adr` and `docs/architecture` (v0.1,
2026-11-06) against the legacy code on `develop` at `752a5de`.

Revised versions of every document live in `docs/adr-revised` and
`docs/architecture-revised`. They are copies of the originals with the changes below applied,
so `diff -r docs/architecture docs/architecture-revised` shows exactly what moved. One new
decision record was added: [ADR-0011](adr/0011-user-identity-is-email.md).

## Verdict

The design is sound and unusually well argued for a v0.1: the big calls (Postgres-only cells,
RLS on top of app scoping, immutable form versions, idempotent append-only sync, projection
for reporting) are right for the stated goals, and the legacy assessment is accurate in every
claim I could check. The holes are mostly in the places where a good idea meets a concrete
mechanism: three of them would silently violate the number-one quality attribute ("never
lose, duplicate or silently alter a submission"), and two would make the tenant-isolation
tests pass without testing anything. All are fixable now at the cost of a few paragraphs; most
would cost a migration or a protocol version later.

## Findings that would break a stated guarantee

### F1. The sync cursor can skip changes forever
`ADR-0007`, `05 — Sync cursor`. A per-agency monotonically increasing `bigint` stamped on rows
at write time does not give devices a gap-free stream. Two transactions take versions 10 and
11; the one holding 11 commits first; a device reads "everything > 9", receives 11, stores
cursor 11; version 10 commits a moment later and is never delivered. The device misses a form
publication, a revocation, or a project pause, permanently. This is the classic
sequence-as-cursor race and it will happen under ordinary concurrency.

**Fix.** Make the stream an append-only `sync_events` table and assign `seq` under a per-agency
transaction-scoped advisory lock (`pg_advisory_xact_lock(agency_id)`) so events commit in
sequence order. Devices read `seq > cursor`. Test it with concurrent writers in the idempotency
suite. Applied in ADR-0007, 05, 10.

### F2. Dashboards wait for photos
`04 — Submission lifecycle`, `02 — Request paths`, `ADR-0010`. Processing (validation, flags,
projection, earnings, Turbo broadcast) runs only after the submission reaches `Complete`, which
means every attachment has arrived. On 2G, photos trail answers by hours or days, so the
"≤ 60 s to dashboard" target and the client's near-real-time expectation fail exactly where
the product is supposed to shine, and earnings are delayed with them.

**Fix.** Process on `Received`. Attachment completeness is a separate dimension
(`attachments_pending` flag; cleared and re-projected when the last file lands). Applied in
04, 02, 05, 06, ADR-0010.

### F3. A `409` strands data on the phone
`ADR-0007`, `05 — Upload sequence`. Same id with a different checksum returns `409` and the
device "keeps data for support". There is no path from that state to the server, so the only
copy of the conflicting payload lives on a phone that may be lost, wiped or handed to someone
else. That is a data-loss path by design, however rare.

**Fix.** The server quarantines the conflicting payload in `submission_conflicts` (visible to
agency admins and support, excluded from reporting) and answers `409 {quarantined: true}`;
the device may then mark the item `conflicted` and stop retrying. Also: an id collision
across tenants (a tampered client reusing another agency's id) must produce `409`, not a
phantom `201`, because under RLS the conflicting row is invisible to the `SELECT` that follows
`ON CONFLICT DO NOTHING`. Applied in ADR-0007, 05, 04 (new `id_conflict` flag).

### F4. 05 and 07 disagree about revoked members
`05 — Login and offline access` says revocation "takes effect on next contact; pending data is
still uploaded before the local session is wiped". `07 — Authentication` says device tokens
are revoked when a membership is removed. A revoked token gets `401`, so the outbox cannot
drain and the captures are lost. Removing a footsoldier at the end of a campaign is the
normal case, not the edge case.

**Fix.** Device sessions get a `draining` state: for a grace period (30 days) the token may
only `PUT` submissions and attachments whose `captured_at` predates `revoked_at` (plus clock
tolerance); every other call is `401`. Removing a member sets `draining`; an owner can
hard-revoke, audited, and the UI says that unsynced captures will be lost. Applied in 03, 05,
07, ADR-0007.

### F5. The sizing assumption contradicts "comfortable on Postgres"
`01 — Assumptions`: 500k submissions/day peak per cell. `ADR-0010`: one projection row per
answer, "acceptable at assumed volumes; partition by month if it grows". At 500k/day and
roughly 20 answers each, the projection grows by 10M rows and about 1 GB a day, 3.6B rows a
year. That is not a "small cell on a 4 vCPU VM" workload, and "add a read replica if wrong"
does not address write volume.

**Fix.** Either number is defensible, but not both. The revision states a realistic planning
peak (100k/day, 20 per active footsoldier) and a 500k/day ceiling that triggers a dedicated
DB host, and it partitions `submissions`, `submission_values` and `audit_events` by month from
the first migration. Partitioning is free at creation and painful at 100M rows. Applied in 01,
ADR-0010, 06, 08, 11.

### F6. The RLS layer as written would fail in five specific ways
`ADR-0004`, `07 — Tenant isolation`, `10 — Tenant isolation suite`. The idea is right; the
mechanism needs these details or the second safeguard is not there:

1. `current_setting('app.agency_id')::bigint` raises when the setting is absent or empty
   rather than returning no rows. Policies must use
   `NULLIF(current_setting('app.agency_id', true), '')::bigint` to fail closed.
2. Table owners bypass RLS. Rails test databases are owned by the test role, so the isolation
   suite would pass with RLS doing nothing. Every tenant table needs `FORCE ROW LEVEL
   SECURITY`, and tests must connect as a non-owner role.
3. Any second connection inside a request (`load_async`, a second database, a job spawned
   inline) has no session variable and silently returns zero rows. Set the variable in a
   connection-pool checkout hook keyed from `Current`, not per request, and forbid
   `load_async` until that hook exists.
4. Session-level `SET` leaks across clients behind a transaction-mode pooler (PgBouncer).
   Either forbid transaction pooling for the app role or use `SET LOCAL` inside a transaction.
5. Several legitimate queries run before a tenant exists: listing a user's memberships for the
   agency switcher, invitation token lookup, device login. With fail-closed policies they
   return nothing. They need explicit user-keyed policies
   (`user_id = current_setting('app.user_id')`), not a `BYPASSRLS` escape hatch.

Two hardening points go with it: composite foreign keys
(`(agency_id, project_id) REFERENCES projects (agency_id, id)`) so a denormalized `agency_id`
cannot disagree with its parent, and support-access grants should run through the RLS role
with `app.agency_id` set to the granted agency, so even support reads keep both safeguards.
Applied in ADR-0004, 03, 07, 10.

## Decisions the docs defer but the evidence says to make now

### F7. Identity: email-only users exclude field agents
`03 — User (email unique)`, README open question 4. The legacy `users` table requires a
phone number for every user and `after_sign_in_path_for` routes promoters first, so the
agents are the primary users, and many will have no email. Changing the identity key after
Phase 0 touches users, invitations, device sessions and audit.

**Fix.** New [ADR-0011](adr/0011-user-identity-is-email.md): identity is email
or E.164 phone, both nullable and unique; invitations by email link or SMS code through an
in-country SMS provider configured per cell. Open question 4 becomes a recommendation.

### F8. Corrections and follow-up records are Phase 4 features with Phase 1 evidence
`11 — Roadmap`, `03 — Correction (later phase)`. The legacy UnionPay tables carry `edited_by`
and the index hides edited rows: editing after capture was needed in the first campaign. BK
Arena, the most recent campaign, is a two-step record (promoter pre-registers; a branch agent
later issues a card against it). Both are deferred to Phase 4.

**Fix.** Add `parent_submission_id` and `kind` (`capture` / `follow_up` / `correction`) to
`submissions` in the Phase 1 schema (free now, a migration later); ship corrections inside the
Phase 1 review flow; move multi-step records to Phase 3. Applied in 03, 04, 11, 00.

### F9. Cascading selects and shared option lists are not "later"
`04 — Field types (later: cascading selects)`. Every Rwandan address form is
province → district → sector → cell → village (the BK Arena form has all five), and the
UnionPay form repeats a hard-coded acquirer list in five fields. A Phase 1 form builder
without shared, cascading choice lists forces admins to paste hundreds of options per form.

**Fix.** `ChoiceList` entity (agency-owned, versioned, with platform-provided lists such as
Rwanda administrative units) and `choices_from` / `cascade_from` on `select_one` in spec v1.
Applied in 04, 03, 11, ADR-0005.

### F10. Dashboards can only count
`06 — Dashboards`. Every widget counts submissions. The Engen report sums a numeric answer
(`fueled_value`) per day and per promoter; any sales or volume campaign needs the same.

**Fix.** `aggregate: count | sum | avg | min | max` over a numeric field on KPI, time-series
and leaderboard widgets. Applied in 06.

### F11. The legacy app leaked a credential into git
`00 — Legacy assessment`. `config/environments/production.rb` contains a literal mail
username and password (committed 2022-08-11, not an `ENV` reference), and the app was
deployed at `rgdata.rw` sending mail through Gmail. Tagging `legacy-v1` keeps the secret in
history forever.

**Fix.** Rotate the credential now, before anything else; record it as a Phase 0 task; note in
the assessment that legacy email left the country. Applied in 00, ADR-0002, 11.

## Gaps in the design

### F12. Multi-agency footsoldiers and shared phones are not designed
`01` lists "shared devices" as a working condition; `03` lets a user hold memberships in
several agencies; `05` gives a device one token, one outbox and a per-agency cursor, and
says nothing about either case. Freelance field agents work for several agencies.

**Fix.** A device session belongs to the user, `GET /sync` covers every active footsoldier
membership with a cursor per agency, and each outbox row carries its `agency_id`. For shared
phones, v1 states the rule plainly: one account per device at a time; switching needs an
empty outbox and connectivity; multi-profile is a later feature. Applied in 05, 03.

### F13. JSONLogic cannot do what forms need without extensions
`ADR-0006`, `04`. Plain JSONLogic has no date arithmetic, no regex, and no defined way to
reference sibling fields inside a repeat instance. Age from date of birth, "within the project
window", "sum of this repeat" are routine form rules. Implementations also disagree on
truthiness and loose equality.

**Fix.** The spec names the operator allowlist, adds a small custom operator set
(`date_diff`, `today`, `matches`, `count`, `sum`, `any`, `all` over repeats), defines strict
equality only, and fixes the `var` scoping convention (relative to the current repeat
instance; `/` prefix for the root). All of it is covered by conformance vectors. Applied in
ADR-0006, 04.

### F14. Form evolution rules are incomplete
`ADR-0005`, `04`. Keys are stable, but nothing says option `value`s are, nothing stops a key
changing type between versions (which breaks the single-typed projection), and nothing says
which version's labels a cross-version dashboard shows.

**Fix.** Publish-time lints: option values stable; a key's type may not change (new key
instead); labels resolve from the latest version that carries the value. Applied in ADR-0005,
04, 06.

### F15. The smallest cell has no off-host backup
`08 — Runtime components / Backups`. The small cell uses Active Storage `Disk` on the same VM,
and backups go "to object storage". On that cell the object store is the same disk as the
database. A disk failure takes both.

**Fix.** Minimum requirement for every cell, including the smallest: backups land on a second
host or an in-country bucket; the weekly restore drill proves it. Also state that Postgres
failover is manual (the 4 h RTO already allows it). Applied in 08, ADR-0008.

### F16. Phase 1 web capture loses a form on a dropped connection
`01` says phase 1 is browser capture "with connectivity"; `11` says Phase 1 exits when a real
agency runs a real campaign. That campaign will run on Rwandan field networks. A refresh,
crash or failed `POST` loses the whole form.

**Fix.** Not full offline, but: autosave the draft to IndexedDB under the submission's UUID,
retry the idempotent submit with backoff, and restore the draft on reload. Applied in 05, 11.

### F17. Rate limits can block the outbox
`07 — Application security baseline` rate-limits the device API. A footsoldier returning
after a day offline has hundreds of `PUT`s to send; a generic limit turns "never block
uploading" into a wall.

**Fix.** Limits on authentication and `GET` endpoints; `PUT` submissions and attachments are
limited per device at a rate well above any honest outbox (for example 600/min) and only
alert, never reject, below an abuse threshold. Applied in 07, 05.

### F18. A wrong clock also kills TLS
`05 — Edge cases` handles a clock wrong by days. A clock wrong by months or years fails
certificate validation and the device cannot reach the server at all, which looks like
"sync broken" to the footsoldier.

**Fix.** Detect the TLS error class on the device, show "fix your phone's date and time",
and keep the outbox untouched. Applied in 05.

## Smaller inconsistencies and omissions

- **"≤ 4 runtime components"** (`01`) versus Prometheus, Grafana, Loki, GlitchTip in `08`.
  Reworded: the limit counts components on the request path; observability is separate and
  optional on the small cell.
- **Turbo Stream broadcasts** must carry a refresh signal only, never rendered data, because
  the broadcast has no tenant or client-view context (`06`).
- **Pseudonyms** ("Agent 07") must be stable per project, or clients will correlate across
  reloads (`06`).
- **Generated exports** contain PII and sit in the object store; delete after 7 days (`06`).
- **Memberships** need a uniqueness rule, `(agency_id, user_id, client_id)` (`03`).
- **Attachment upload** stays single-request, but the endpoint reserves `Content-Range` and a
  `HEAD` for received bytes so resumable upload later is an additive change (`05`, `04`).
- **Device id** on Expo is not a hardware id; generate a UUID at first launch and keep it in
  the secure store (`05`, `ADR-0009`).
- **iOS background sync** is best-effort; the design relies on foreground sync (`05`,
  `ADR-0009`).
- **Compliance checklist** for the Rwanda cell: the data-protection law also expects
  controllers and processors to register with the NCSA; confirm with counsel (`07`).
- **`.agents/` is git-ignored** (`12`), which makes it invisible in every git worktree and in
  CI. This review ran in a worktree that did not contain `docs/` for the same reason. The
  folder holds no secrets by its own rules; commit it. The "no AI attribution" convention
  should be enforced by `includeCoAuthoredBy: false` in `.claude/settings.json` rather than by
  asking agents to remember.
- **Legacy assessment corrections** (`00`): card issuance is done by a user flagged
  `is_bk_arena_agent`, not an admin; anyone can self-register (`:registerable`) and is then
  approved by posting a shared `admin_secret_key`, which the new invitation model must not
  reproduce; search by ID number or phone across all records (`issue_card#search`) is part
  of the follow-up workflow; the deployment target was `rgdata.rw`.

## What I checked and found correct

Stack versions, table and column names, the role flags, the `after_sign_in_path_for` chain,
the `.length`-based percentage reports, per-model `to_csv`, the absence of deployment config,
the commit count and date, the unique `id_number` index, the array column
`merchant_has_multiple_acquirers`, and the scaffold-only tests (fixtures are empty hashes).
The Rwanda residency citation and the RWF minor-unit note match my understanding. The
alternatives considered in each ADR are fairly stated.

## Response to the review

2026-11-09. Each finding was checked against the v0.1 documents and the legacy code; every
factual claim held up. The revised documents are now the main copies in `docs/adr` and
`docs/architecture` (the `-revised` folders described above were folded into them), with the
changes below on top of the reviewer's revision.

### Accepted as written

F1–F4, F10–F12, F14–F18, and the smaller items not listed below. For F12, the product owner
kept one account per phone and dropped multi-profile support entirely (decision 6, below).

### Accepted with changes

| Finding | Change to the reviewer's fix | Why |
|---------|------------------------------|-----|
| F5 sizing and partitioning | `submissions` is **not** partitioned. `submission_values` and `audit_events` are, keyed on server time (`received_at`, `occurred_at`). | Postgres requires every unique key on a partitioned table to include the partition key. Partitioning `submissions` by month turns the primary key into `(id, month)`, so the same id could be stored twice and `ON CONFLICT (id)` (the idempotency and `409` detection that F3 relies on) stops working. Device time is not a safe partition key because phone clocks can be years off. |
| F6 RLS mechanism | Tests also run as a **non-superuser**. `load_async` is disabled in v1, not "until the hook exists". Invitation acceptance uses one `SECURITY DEFINER` lookup function, not a user-keyed policy. | Superusers bypass even forced RLS. `load_async` runs on executor threads that do not carry `Current`, so a checkout hook cannot see the tenant there. An invitee may have no account yet, so there is no `app.user_id` to key on. |
| F7 identity | **Overruled by the product owner (2026-11-09).** Email stays the identity; a phone number is required for footsoldiers as a contact channel, and is a possible later second factor ([ADR-0011](adr/0011-user-identity-is-email.md), accepted). | The legacy `users` table also required an email (a Devise default), so it does not show that agents lack one. With email identity no cell needs an SMS provider in v1. |
| F8 corrections | The original footsoldier may also author corrections when the project allows it. | In the legacy app the edits were made by promoters, not reviewers. A device-made correction is a new submission with its own UUID, so the protocol is unchanged. |
| F9 choice lists | Publishing a form version **pins the choice-list versions** it uses. | Otherwise editing a list silently changes a published form that ADR-0005 says is immutable. |
| F13 JSONLogic | Loose `==`/`!=` are left off the allowlist instead of being redefined as strict. `today()` evaluates to the submission's `captured_at`. | Every off-the-shelf JSONLogic library reads `==` as loose. If the server evaluated `today()` against its own clock, a rule like "date not in the future" would pass on the phone and fail on the server, raising false `validation_failed` flags. |
| Membership uniqueness | `UNIQUE NULLS NOT DISTINCT (agency_id, user_id, client_id)`. | A plain unique index treats `NULL` client ids as distinct and allows duplicate agency-level memberships. |
| Attribution setting | The Claude Code setting is not named in the doc. | It has been renamed across versions; check the current name when adding it. |

### Added (not in the review)

- **Sync stream lifecycle.** A device with no cursor, or one older than a 90-day window, gets
  a snapshot of current state plus the current `seq` instead of replaying the agency's whole
  history; older events are pruned. Review outcomes and earnings now travel on the same
  stream: the old `GET /submissions?since=` timestamp had the same race as F1, plus the
  clock problem. Added an immutable `GET /choice_list_versions/:id`.
- **Web filler drafts** in IndexedDB are deleted on acknowledgement and on logout, because
  browsers are often shared.
- **F11 is more urgent than stated.** The GitHub repository is public, so the mail credential
  has been readable by anyone since 2022-08-11. Treat it as compromised, not only as committed.

### Product-owner decisions (2026-11-09)

The README's open questions were answered; the documents now reflect them
([architecture README](architecture/README.md#product-owner-decisions-2026-11-09)):

1. No legacy data is migrated or archived. The importer epic (E1.12) and the
   `legacy_import` channel are removed.
2. A client may be served by several agencies, with one `Client` record per agency and no
   combined data.
3. React Native (Expo) for mobile; [ADR-0009](adr/0009-mobile-stack.md) accepted.
4. Email is the identity, which overrules F7; a phone number is required for footsoldiers so
   they can be reached (optional for others), but is not a login. [ADR-0011](adr/0011-user-identity-is-email.md)
   rewritten and accepted.
5. Single trunk `main`; `main` was fast-forwarded to `develop` and made the default branch on
   2026-11-09, and `develop` is deleted in E0.1.
6. Footsoldiers work for several agencies and borrow each other's phones. A borrower logs in
   with their own details: one account per phone at a time, logout only once the outbox has
   synced, as F12 proposed. The Phase 4 multi-profile epic is removed, and a `shared_device`
   quality flag is added so reviewers can see when one phone captured for two footsoldiers.
7. Deployment: a demo with the full flow but no real campaign data runs on the team's Coolify
   server, with Garage for files and backups off the server (F15 applies there too).
   Production cells run on Linux servers in the client's country with Kamal, from the first
   signed client; the Kamal path is proven on a throwaway VM before any client signs. No
   Cloudflare edge services.
