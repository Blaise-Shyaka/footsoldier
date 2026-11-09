# 03 — Domain model and access control

## Core entities

```mermaid
erDiagram
  USER ||--o{ MEMBERSHIP : has
  AGENCY ||--o{ MEMBERSHIP : has
  AGENCY ||--o{ CLIENT : serves
  CLIENT ||--o{ MEMBERSHIP : "client users (client_id set)"
  AGENCY ||--o{ PROJECT : runs
  CLIENT ||--o{ PROJECT : commissions
  PROJECT ||--o{ ASSIGNMENT : has
  MEMBERSHIP ||--o{ ASSIGNMENT : "footsoldier"
  PROJECT ||--o{ FORM : has
  FORM ||--o{ FORM_VERSION : versions
  FORM_VERSION ||--o{ SUBMISSION : "captured with"
  MEMBERSHIP ||--o{ SUBMISSION : authors
  SUBMISSION ||--o{ ATTACHMENT : has
  SUBMISSION ||--o{ SUBMISSION_VALUE : "projected into"
  SUBMISSION ||--o{ REVIEW_EVENT : reviewed
  PROJECT ||--o{ DASHBOARD : has
  PROJECT ||--o{ COMPENSATION_RATE : "opt-in"
  SUBMISSION ||--o| EARNING_ENTRY : earns
  AGENCY ||--o| THEME : brands
  CLIENT ||--o| THEME : brands
  AGENCY ||--|| SUBSCRIPTION : "plan"
  USER ||--o{ DEVICE_SESSION : "mobile logins"
```

### Identity and tenancy

| Entity | Key fields | Notes |
|--------|-----------|-------|
| `User` | email (unique, citext), name, phone, password_digest, confirmed_at, locale, otp_secret | One identity per person per cell. Not tenant-scoped. |
| `Agency` | slug, name, status (`active`/`suspended`), data_region | **The tenant root.** |
| `Client` | agency_id, name, status | Belongs to exactly one agency. A real-world organization served by two agencies is two `Client` records (isolation over convenience — see open question 2). |
| `Membership` | agency_id, user_id, client_id (nullable), role, status, invited_by | A user's role in one agency. Client users have `client_id` set. A user can hold memberships in several agencies. |
| `Invitation` | agency_id, email, role, client_id, token_digest, expires_at, accepted_at | Email link → set password / confirm → membership activated. |
| `DeviceSession` | user_id, device_id, token_digest, platform, app_version, last_seen_at, revoked_at | Long-lived, revocable API token per device. |
| `PlatformStaff` | email, password_digest, otp_secret, role | **Separate table and login** from tenant users. |

Roles on `Membership`:

| Role | Scope |
|------|-------|
| `agency_owner` | Everything in the agency, including billing and deleting data |
| `agency_admin` | Clients, projects, forms, members, client view config, exports |
| `agency_supervisor` | Assigned projects only: review submissions, view dashboards, manage assignments |
| `footsoldier` | Assigned, active projects only: capture and view own submissions and earnings |
| `client_admin` | Projects of their client: dashboards, exports allowed by the agency, invite client viewers |
| `client_viewer` | Projects of their client: dashboards only |

One membership = one role. Someone who is both a supervisor and a footsoldier holds the higher
role; capture permission for supervisors is a project setting, not a second role.

### Projects

| Entity | Key fields | Notes |
|--------|-----------|-------|
| `Project` | agency_id, client_id, name, description, status, starts_on, ends_on, settings (jsonb) | `status`: `draft` → `active` ⇄ `paused` → `closed`. Only `active` projects accept new captures. |
| `Assignment` | agency_id, project_id, membership_id, status, activated_at, revoked_at, revoked_by_id | Footsoldier ↔ project. Revocation is a status change, never a delete. |

Project settings (typed via `store_accessor`, validated): `gps_policy`
(`off`/`optional`/`required`), `share_location_with_client`, `pseudonymize_footsoldiers_for_client`,
`compensation_enabled`, `review_mode` (`none`/`sample`/`all`), `retention_days`.

### Forms and submissions

Detailed in [04](04-forms-and-submissions.md). Summary:

| Entity | Notes |
|--------|-------|
| `Form` | Belongs to a project; has a stable `key`. |
| `FormVersion` | `definition` (jsonb), `version` (int), `status` (`draft`/`published`/`retired`), `checksum`. Published = immutable. |
| `Submission` | Client-generated UUIDv7 id; `answers` (jsonb, as captured); device/timing/location metadata; `state` and `review_status`. Never updated in place except status columns. |
| `Attachment` | Client-generated UUID; belongs to submission + field key; Active Storage blob; checksum. |
| `SubmissionValue` | Typed projection row per answered field (for analytics). Rebuildable. |
| `ReviewEvent` | Append-only: accepted / flagged / rejected / note, by whom, why. |
| `Correction` | Later phase: agency-made correction to one answer, keeping original. |

### Every tenant-owned table has `agency_id`

Even when derivable through a parent (e.g. `submissions.project_id → projects.agency_id`),
`agency_id` is denormalized onto the row. This makes tenant scoping a single indexed predicate
and makes PostgreSQL row-level security possible ([ADR-0004](../adr/0004-multi-tenancy.md)).

Primary keys: `bigint` for server-created rows; **UUIDv7** for anything a device creates
(submissions, attachments), so ids can be generated offline and still sort by time.

## Authorization

Authorization has three layers, all of which must pass:

1. **Tenant context** — the request resolves `Current.agency` from the membership the user
   selected (agency switcher for multi-agency users). All tenant models are scoped to it, and
   the DB session variable for RLS is set to it.
2. **Role** — Pundit policy for the action, based on `Current.membership.role`.
3. **Resource scope** — supervisors and footsoldiers are limited to projects they're assigned
   to; client users to their client's projects; footsoldiers to their own submissions.

### Permission matrix (v1)

| Action | owner | admin | supervisor | footsoldier | client_admin | client_viewer | platform |
|--------|:-----:|:-----:|:----------:|:-----------:|:------------:|:-------------:|:--------:|
| Manage billing / plan | ✓ | | | | | | ✓ (plan) |
| Manage members & invitations | ✓ | ✓ | assign only | | client viewers | | |
| Manage clients | ✓ | ✓ | | | | | |
| Create / edit projects | ✓ | ✓ | | | | | |
| Build & publish forms | ✓ | ✓ | | | | | |
| Capture submissions | | | if allowed | assigned + active | | | |
| View submissions (raw) | ✓ | ✓ | assigned | own | if allowed by agency | | |
| Review / flag / reject | ✓ | ✓ | assigned | | | | |
| Configure client view | ✓ | ✓ | | | | | |
| View dashboards | ✓ | ✓ | assigned | own stats | client-visible | client-visible | |
| Export data | ✓ | ✓ | | | if allowed | | |
| See compensation | ✓ | ✓ | assigned | own | | | |
| Brand agency / client | ✓ | ✓ | | | | | |
| Read answer content | | | | | | | only via support grant |

## Lifecycle rules worth stating explicitly

- **Revoking an assignment** stops new captures from the next sync, but submissions captured
  *before* `revoked_at` (by device capture time, with clock-skew tolerance) are still
  accepted — and flagged for review if they arrive after revocation.
- **Pausing a project** blocks new captures; in-flight data is still accepted.
- **Removing a member** deactivates the membership and revokes their device sessions;
  their submissions stay, attributed to them.
- **Deleting is rare and explicit.** Only `agency_owner` can delete a project's data, through
  an audited, delayed (soft → hard after N days) process.
