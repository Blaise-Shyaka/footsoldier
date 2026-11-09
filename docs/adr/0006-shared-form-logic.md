# ADR-0006: JSONLogic for form logic, with a cross-runtime conformance suite

- Status: Proposed
- Date: 2026-11-06

## Context

Skip logic, conditional requirements, validation rules and calculated fields must give the same
result on the device (to guide the footsoldier) and on the server (to verify and flag). If they
disagree, either the footsoldier is blocked wrongly or bad data is accepted silently.

## Decision

- Express all form logic in **JSONLogic**, a small, side-effect-free JSON expression format with
  implementations available in Ruby and JavaScript/TypeScript.
- Implement one **form runtime** per language, logic only (no UI):
  - TypeScript (`packages/form-runtime`), used by the web form filler, the builder preview and
    the mobile app;
  - Ruby (inside the Rails app), used for server-side validation and flags.
- Maintain **conformance test vectors** in `packages/form-spec/conformance`, executed against
  both runtimes in CI. Restrict operators to an allowlisted subset we test.
- *Revised:* plain JSONLogic lacks date arithmetic, regex and a rule for referencing fields
  inside a repeat instance, and implementations disagree on truthiness and loose equality.
  The spec therefore defines:
  - the **operator allowlist** (`==` is strict; `===`/`!=`/`!==`, `and`, `or`, `!`, `if`,
    comparisons, arithmetic, `in`, `cat`, `var`, `missing`, `merge`, `map`/`filter`/`reduce`);
  - **custom operators** implemented in both runtimes: `date_diff(a, b, unit)`, `today()`,
    `matches(str, regex)` (RE2-safe subset), and `count`/`sum`/`any`/`all` over a repeat group;
  - **`var` scoping:** inside a repeat, `var` resolves relative to the current instance;
    a leading `/` addresses the root (`{"var": "/merchant_name"}`); `$index` is the current
    repeat index.
  Every custom operator and scoping rule has conformance vectors before it is used in a form.

## Consequences

- Two implementations (Ruby, TS) instead of three — a key reason for choosing React Native for
  mobile ([ADR-0009](0009-mobile-stack.md)).
- Logic is data: safe to store, diff, generate with AI and validate.
- Complex logic is verbose in raw JSONLogic; the builder must offer a friendly rule editor.

## Alternatives considered

- **Custom expression language** — nicer syntax, but we'd write and maintain parsers in each
  language.
- **XPath (as in ODK)** — powerful, but heavy to implement and test in two runtimes.
- **Server-only validation** — breaks offline guidance; footsoldiers would discover errors
  after leaving the site.
