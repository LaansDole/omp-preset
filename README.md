# omp-preset

Portable Oh-My-Pi (**omp**) harness — the user-scope config, custom task agents,
watchdog, plugin list, and the PR-description skill, ready to install on any
machine. This is **not an omp fork**: a fork would pin you to a rebuilt binary and
increase staleness; this repo always installs the current omp and only carries the
*portable* layer (config + agents + extensions), which is what a fork cannot capture.

See `AGENTS.md`/`docs` discussion in `~/Projects/omp-tldr` and the `oh-my-pi` Hermes
skill for the rationale.

## What's ported (and what's not)

**Ported (version this):**
- `config.yml` — source-of-truth settings (modelRoles, advisor, task overrides).
- `agents/*.md` — custom task agents: `reviewer`, `reviewer-deep`, `tldr`, `pr`.
- `WATCHDOG.md` — advisor review-priority guidance.
- `plugins.json` — installed extension list + install refs (never copy `node_modules`).
- `skills/writing-pr-descriptions/SKILL.md` — the PR-description standard the `pr`
  agent reads.

**NOT ported (machine-specific / secrets; do NOT commit):**
- `~/.omp/agent/agent.db*` (OAuth credentials), `history.db`, `models.db`,
  `sessions/`, `logs/`, `cache/`, `blobs/`, `install-id`, `autoqa.db`.

## Install on a new machine

```bash
git clone <this-repo> ~/omp-preset
cd ~/omp-preset
./bootstrap.sh            # default profile
# or for an isolated profile:
OMP_PROFILE=work ./bootstrap.sh
```

`bootstrap.sh` copies `config.yml` + `agents/*.md` + `WATCHDOG.md` into the active
omp agent dir (`~/.omp/agent` by default, `~/.omp/profiles/<name>/agent` when a
profile is set, or `$PI_CODING_AGENT_DIR`), places the PR skill so the `pr` agent's
reference resolves, and re-installs plugins by reference. It leaves machine-specific
state untouched.

After bootstrapping on a fresh machine, **re-login to your providers** (`opencode
auth login` → anthropic) — the OAuth credential in `agent.db` is not portable.

## Keeping it current as omp evolves

omp is fast-moving; config/agent schemas can change between versions (e.g. v17→v18
reshaped `modelRoles` and added `advisor`, `agentModelOverrides`, `prewalk`). How to
handle:

1. Running the binary: always install the **latest** omp — never pin. (No fork keeps
   you current; a fork freezes you to your last merge.)
2. When omp releases and your config/agents warn or break:
   - `omp config list` to see current keys; update `config.yml` here.
   - Keep custom config **minimal and layered as an overlay** (`--config <file>` /
     `PI_CONFIG_FILES`) so you carry few keys that can drift.
3. Unknown config keys in omp are tolerated (warnings, not crashes), and omp
   auto-migrates legacy config — drift is recoverable.

Re-run `./bootstrap.sh` after pulling an update to re-sync into the active profile.