# omp-preset

Portable Oh-My-Pi (**omp**) harness — the user-scope config, custom task agents,
statusline, watchdog, plugin list, and the PR-description skill, ready to install
on any machine. This is **not an omp fork**: a fork would pin you to a rebuilt
binary and increase staleness; this repo always installs the current omp and only
carries the *portable* layer (config + agents + extensions), which is what a fork
cannot capture.

The repo is **also a pi/omp package** (`package.json` manifest) — see
[Package install](#package-install) below.

See `AGENTS.md`/`docs` discussion in `~/Projects/omp-tldr` and the `oh-my-pi` Hermes
skill for the rationale.

## What's ported (and what's not)

**Ported (version this):**
- `config.yml` — source-of-truth settings (modelRoles, advisor, task overrides).
- `agents/*.md` — custom task agents: `reviewer`, `reviewer-deep`, `tldr`, `pr`.
- `statusline.sh` — Claude Code-compatible statusline command (model, context %,
  zone hint, cost, git branch) fed by the `pi-statusline` extension.
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

`bootstrap.sh` copies `config.yml` + `agents/*.md` + `WATCHDOG.md` +
`statusline.sh` into the active omp agent dir (`~/.omp/agent` by default,
`~/.omp/profiles/<name>/agent` when a profile is set, or `$PI_CODING_AGENT_DIR`),
merges the `statusLine` block into `~/.pi/agent/settings.json` (the path the
`pi-statusline` extension reads — omp's `config.yml` is NOT consulted for it),
places the PR skill so the `pr` agent's reference resolves, and re-installs
plugins by reference. It leaves machine-specific state untouched.

After bootstrapping on a fresh machine, **re-login to your providers** (`opencode
auth login` → anthropic) — the OAuth credential in `agent.db` is not portable.

## Statusline

The `pi-statusline` extension (npm) pipes a Claude-Code-compatible JSON payload
(model, context-window usage, cost, session) into `statusline.sh` on stdin and
renders its stdout as the TUI footer. The script shows:

```
Fable 5 ┃ ctx 42% [code] ┃ $1.23 ┃ main*
```

- `ctx` zone hints (the idea comes from u/luongnv-com's `statusline-pi` from
  r/PiCodingAgent): `[code]` ≤ 59% used → plenty of room; `[wrap up]` 60–84% →
  finish the current task; `[NEW SESSION]` ≥ 85% → start fresh.
- Tunables at the top of `statusline.sh`: `CODE_ZONE_MAX`, `WRAP_ZONE_MAX`.
- Settings live in `~/.pi/agent/settings.json` under `statusLine`
  (`placement`, `padding`, `debounceMs`, `timeoutMs`); bootstrap merges them
  without touching your other pi settings (e.g. `piWarp`).

## Package install

The repo doubles as a pi/omp package (`package.json` with `omp`/`pi` manifests).
What the package path covers vs. what still needs `bootstrap.sh`:

| Piece | Package path | bootstrap.sh |
|---|---|---|
| Task agents (`agents/*.md`) | yes — package roots are scanned for `agents/` | copied into `~/.omp/agent/agents/` |
| Skills (`skills/`) | yes — `omp`/`pi` manifest `skills` key | copied to `~/.agents/skills/` |
| config.yml / WATCHDOG.md | no — not package-scannable | copied |
| statusline.sh + pi settings | no — settings live outside omp | copied + merged |
| plugins by ref | no — needs `omp plugin install` | reinstalled |

Install as a package (after cloning):

```bash
omp plugin install ~/Projects/omp-preset   # user scope
# or development mode — edits take effect without reinstall:
omp plugin link ~/Projects/omp-preset
```

`bootstrap.sh` remains the full-fidelity path: it covers everything in the table,
including the pieces the package format cannot express. Use the package link for
agents + skills (auto-updating while linked); use bootstrap for the complete
setup, or both.

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
