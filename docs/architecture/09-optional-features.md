# 09 — Optional and paid features

## Plans and entitlements

Free vs paid is a **business** decision expressed as data, not as code branches.

| Entity | Fields |
|--------|--------|
| `Plan` | `key` (`free`, `pro`, `enterprise`…), name, price, `entitlements` (jsonb) |
| `Subscription` | agency_id, plan_id, status, current_period_start/end, overrides (jsonb) |
| `UsageCounter` | agency_id, metric, period, value (submissions, storage bytes, active footsoldiers, AI calls) |

Entitlements are either **features** (boolean) or **limits** (numbers):

```json
{
  "features": { "ai_form_assist": true, "compensation": true, "client_branding": true,
                "client_dashboards": true, "exports_xlsx": true, "ai_insights": false },
  "limits":   { "active_projects": 20, "active_footsoldiers": 200,
                "submissions_per_month": 100000, "storage_gb": 50 }
}
```

- Checked through one API: `Current.agency.entitled_to?(:compensation)` and
  `Current.agency.within_limit?(:active_footsoldiers)`.
- UI shows locked features with an upgrade prompt rather than hiding them.
- **Limits never block data capture already in flight.** Exceeding `submissions_per_month`
  warns the agency and the operator; it does not reject footsoldier uploads (reliability first).
- Which features are free vs paid is a pricing decision for the product owner; the table above
  is an example only.
- Payment collection (card, mobile money, invoice) is a later integration behind a
  `Billing::PaymentProvider` interface; v1 can run on manual invoicing with the operator setting
  subscription state in the console.

Feature flags (Flipper) are separate: they control rollout of unfinished features, not what a
customer has paid for.

## Footsoldier compensation (opt-in)

Agencies decide pay; the platform does the counting.

| Entity | Fields |
|--------|--------|
| `CompensationRate` | agency_id, project_id, form_id (nullable = all forms), amount_minor, currency, basis (`per_accepted_submission` in v1), effective_from, effective_to |
| `EarningEntry` | agency_id, membership_id, submission_id, rate_id, amount_minor, currency, status (`pending`/`confirmed`/`voided`) |
| `Statement` | agency_id, membership_id, period, totals, status (`draft`/`final`), exported_at |

Rules:

- Enabled per project (`compensation_enabled`) and gated by the `compensation` entitlement.
- An entry is created when a submission is **accepted**, using the rate effective at
  `captured_at`. Rejecting a previously accepted submission **voids** the entry (never deletes).
- Rate changes are new rows with new effective dates — history never changes retroactively.
- Money is integer minor units + ISO currency (`RWF` has no minor unit in practice; we still
  store integers).
- Agency report: earnings per footsoldier per period, with drill-down to submissions;
  exportable for payroll / mobile-money bulk payment. Footsoldiers see their own running total.
- Later bases: per-day rate, tiered rates, bonuses for quality, deductions for rejected work.

## AI assistants (opt-in)

All AI features are optional, entitlement-gated, configurable per cell, and **produce drafts
for a human to accept** — they never publish or change data on their own.

### Form assistant (phase 3)

- Input: project description, client name/industry, optional example questions.
  **No personal data** is sent.
- Output: a draft form definition (valid against `form-spec`) with rationale per section;
  suggestions for an existing draft ("add a GPS field", "this question is double-barrelled").
- The output is validated against the JSON Schema and the runtime before it is shown; invalid
  output is retried once, then shown as suggestions only.

### Insights assistant (later)

- Explains dashboards for agency and client users.
- Works on **aggregates already computed for widgets**, never on raw answers; respects the
  client view.
- Disabled by default in cells where the AI provider is outside the jurisdiction unless the
  agency confirms the provider is authorised.

### Provider abstraction

- `AI::Client` wraps `ruby_llm`, so the provider (Anthropic, OpenAI, a local model via Ollama,
  etc.) is set per cell by configuration.
- Every call records: agency, feature, model, token counts, latency, outcome — for cost
  tracking (`UsageCounter`) and support. Prompts and outputs are stored only for the form
  assistant (no PII by construction).
