# ADR-0001: Record architecture decisions

- Status: Proposed
- Date: 2026-11-06

## Context

The platform will be built largely by AI agents working task by task, reviewed by people.
Agents start each session without memory; reviewers need to know *why* the code looks the way
it does. Decisions that live only in chat or in someone's head get re-litigated or silently
violated.

## Decision

Keep Architecture Decision Records in `docs/adr/`, one Markdown file per decision, using the
template in the ADR index. Architecture documents in `docs/architecture/` describe the system
and link to the ADRs that justify it. `CLAUDE.md` instructs agents to read relevant ADRs before
working on a module and to propose a new ADR rather than diverge from an accepted one.

## Consequences

- Decisions are reviewable in PRs like code.
- Small decisions not worth an ADR go to `.agents/decisions-log.md` and are promoted if they
  turn out to matter.

## Alternatives considered

- **Wiki / Notion pages** — drift from the code and are invisible to agents working in the repo.
- **No formal records** — fastest now, most expensive later.
