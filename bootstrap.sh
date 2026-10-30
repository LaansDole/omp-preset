#!/usr/bin/env bash
# omp-preset bootstrap — install this repo's portable omp config/agents/WATCHDOG/
# plugins/skills into the active omp profile on this machine.
#
# NOT a fork: this copies omp's user-scope dotfiles into place and re-installs
# plugins by reference. It does NOT touch machine-specific state (agent.db OAuth,
# history.db, models.db, sessions, logs, caches) — log in to Anthropic again after (omp login anthropic).
#
# Target profile: set OMP_PROFILE (or pass nothing for the default profile).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the active omp agent dir.
_profile="${OMP_PROFILE:-}"
if [[ -n "${_profile}" ]] && [[ "${_profile}" != "default" ]] && [[ "${_profile//[[:space:]]/}" != "" ]]; then
  AGENT_DIR="$HOME/.omp/profiles/${_profile}/agent"
else
  AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
fi

command -v omp >/dev/null 2>&1 || {
  echo "ERROR: 'omp' binary not found on PATH. Install omp first (see github.com/can1357/oh-my-pi), then re-run."
  exit 1
}

echo "Targeting agent dir: $AGENT_DIR"
mkdir -p "$AGENT_DIR/agents"

# 1. config.yml (back up an existing one first).
if [[ -f "$AGENT_DIR/config.yml" ]] && [[ ! -f "$AGENT_DIR/config.yml.preset-bak" ]]; then
  cp "$AGENT_DIR/config.yml" "$AGENT_DIR/config.yml.preset-bak"
fi
cp "$REPO/config.yml" "$AGENT_DIR/config.yml"

# 2. custom task agents.
cp "$REPO"/agents/*.md "$AGENT_DIR/agents/"

# 3. watchdog guidance.
cp "$REPO/WATCHDOG.md" "$AGENT_DIR/WATCHDOG.md"

# 3b. rules — agent-requested rules (e.g. impeccable-design: route UI work through Impeccable).
mkdir -p "$AGENT_DIR/rules"
cp "$REPO"/rules/*.md "$AGENT_DIR/rules/"

# 4. skills — each skills/<name>/ copied to ~/.agents/skills/<name>/ (pr agent reads writing-pr-descriptions).
SKILL_DST="${SKILLS_DIR:-$HOME/.agents/skills}"
mkdir -p "$SKILL_DST"
cp -R "$REPO/skills/." "$SKILL_DST/"

# 5. plugins — re-installed by reference; never copy node_modules.
if command -v python3 >/dev/null 2>&1 && [[ -f "$REPO/plugins.json" ]]; then
  python3 -c "import json;d=json.load(open('$REPO/plugins.json'));print('\n'.join(p['ref'] for p in d['plugins']))" |
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    case "$ref" in
      "~/") ref="$HOME/${ref#~/}" ;;
    esac
    if [[ "$ref" == /* ]] && [[ ! -d "$ref" ]]; then
      echo "  (skip) missing local source: $ref"
      continue
    fi
    echo "  install: $ref"
    omp plugin install "$ref" || echo "  (warn) plugin install failed: $ref"
  done
fi

# 6. Impeccable design skill (third-party, pbakaus/impeccable), installed by its own CLI so it stays current.
#    It always lands in ~/.omp/agent/skills/impeccable (the CLI does not follow OMP_PROFILE). Telemetry is turned off.
if command -v npx >/dev/null 2>&1; then
  echo "  install: impeccable (omp, global)"
  npx -y impeccable@latest install -y --providers=omp --global --force >/dev/null \
    && npx -y impeccable@latest telemetry off >/dev/null \
    || echo "  (warn) impeccable install failed; run: npx impeccable install --providers=omp --global"
else
  echo "  (skip) npx not found; install Node.js, then: npx impeccable install --providers=omp --global"
fi

echo
echo "Done."
echo "  config     -> $AGENT_DIR/config.yml  (prior saved as .preset-bak)"
echo "  agents     -> $AGENT_DIR/agents/"
echo "  watchdog   -> $AGENT_DIR/WATCHDOG.md"
echo "  rules      -> $AGENT_DIR/rules/"
echo "  skills     -> $SKILL_DST/"
echo "  impeccable -> $HOME/.omp/agent/skills/impeccable (telemetry off)"
echo "  plugins    -> reinstalled by ref (optional/missing local ones skipped)"
echo
echo "Notes:"
echo "  - Machine-specific state (agent.db OAuth, history.db, models.db, sessions, logs, caches) was NOT ported."
echo "  - Log in to Anthropic before first use: 'omp login anthropic'."
echo "  - If omp changes a config/agent schema in a future release, update this repo (git) and re-run."