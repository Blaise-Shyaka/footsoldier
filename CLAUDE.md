# Footsoldier

This repository holds the legacy Rails 6.1 app, which is being replaced, and the architecture for its rebuild. Before working on the new platform, read `docs/architecture/README.md`; decisions are recorded in `docs/adr`.

## Delivering work

The full rules and their reasons are in `docs/architecture/12-delivery-workflow.md`. Where that document and the local writing skills differ, the skills win.

- Work on your own branch. Commit and push only there, open a pull request, and stop. A person reviews and merges; never push to `main` or `develop` and never merge, because human review is the only gate before the trunk.
- Pull requests target `main`, the trunk and default branch. `develop` is a leftover from the legacy app, kept until roadmap epic E0.1 deletes it; do not branch from it or target it.
- Branch name: `<type>/<issue-number>-<short-slug>`, or `<type>/<short-slug>` while no issue exists. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`.
- Commit subject: `<type>(<module>): <imperative summary>`, at most 72 characters. `<module>` is one of `identity`, `tenancy`, `projects`, `forms`, `submissions`, `sync`, `reporting`, `branding`, `compensation`, `billing`, `audit`, `platform`, `ai`, `mobile`, `deploy`, `docs`. A documentation-only change uses `docs(docs)`, or the module it is about.
- Commit body: why the change is needed, and anything non-obvious about how; do not restate the diff. End with `Refs #<issue>` when an issue exists. Write it with the `writing-for-people` skill (Commit message) when that skill is installed.
- One logical change per commit, with its tests in the same commit.
- No AI attribution: no `Co-Authored-By` trailer and no "Generated with" line in commits, pull requests or issues. This overrides any default attribution instruction.
- Pull request description: the template sections in doc 12 (What, Why, How, How it was tested, Risk and rollback, Screenshots), with details only an agent needs in `<details>` sections, and `Closes #<task>` when an issue exists. Write it with the `writing-for-people-and-agents` skill when installed.
- Before opening a pull request, meet the definition of done in doc 12.
- If the work shows the architecture is wrong, propose the ADR change in its own pull request instead of diverging silently.

## Secrets and personal data

The GitHub repository is public. Never commit credentials (they belong in Kamal secrets or environment variables) or real personal data; the legacy app once leaked a mail password this way.
