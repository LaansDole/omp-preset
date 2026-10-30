---
description: "Any frontend design or UI work: designing, redesigning, restyling, critiquing, auditing or polishing a website, page, dashboard, component, HTML artifact, or design system (PRODUCT.md / DESIGN.md)."
---

# Design work goes through Impeccable

For any UI design task, load the `impeccable` skill (`~/.omp/agent/skills/impeccable/SKILL.md`) before planning or editing, and follow its references instead of improvising a look.

- Start with its Setup: run `~/.omp/agent/skills/impeccable/scripts/impeccable context --target <entry file>` from the project root, then load the playbook for the command (`critique`, `audit`, `polish`, `layout`, `typeset`, ...) or `reference/new-work.md` for a new surface or a restyle.
- No PRODUCT.md: run `reference/init.md` (one interview round, at most 3 questions) and write PRODUCT.md first. A restyle with a new look runs the direction round (`impeccable concept-seed`) and records the direction contract with `impeccable surface-brief write` before any code.
- Read `reference/craft-floor.md` immediately before the first UI edit.
- Finish: run `impeccable detect --json <changed files>` once and fix what it finds, capture desktop (1440) and mobile (390) screenshots and inspect them, then do the finish review from `reference/degraded/finish-reviewer.md` with a fresh reviewer (task agent), and write DESIGN.md plus `.impeccable/design.json` with `reference/degraded/documenter.md`.
- Gitignore Impeccable scratch (`.impeccable/mocks/`, `.impeccable/review/`, `.impeccable/questions/`); keep `.impeccable/surfaces/`, `.impeccable/design.json`, PRODUCT.md and DESIGN.md.

Owner preferences:
- Body text and lists run the full width of their column; do not cap paragraphs at a 65-75ch measure.
- Never encode meaning by hue alone; pair colour with a mark, weight or word.
- Telemetry stays off (`~/.impeccable/config.json`, `"telemetry": false`).
