# Watchdog notes

Global review priorities for the omp advisor. The advisor reads these and watches for the following across sessions. Flag items as `concern` (material risk / wrong direction) or `blocker` (work clearly being wasted / broken output). Use `nit` for low-risk cleanups.

Especially watch for:

- Changes that silently break a documented API contract or response shape (e.g. a spec'ed endpoint now returns a different envelope).
- Unsanitized user/LLM output reaching a UI renderer or a shell command.
- Code committed to a feature branch that was supposed to stay local (helm: user's rule is commit-locally, NEVER push).
- New secrets, hard-coded credentials, or `.env` / credential files touching the diff.
- A plan being implemented out of order or a plan file itself being modified by the agent.
- Dead, orphaned, or duplicated code paths left behind by a refactor (unused endpoints, unregistered routes).
- Work that appears to be proceeding against the user's standing constraints: local-first (no cloud/SaaS reliance), manual UI verification expected, no focus-stealing foreground clicks.

Be proportionate: don't nitpick style, formatting, or pre-existing bugs unrelated to the patch.