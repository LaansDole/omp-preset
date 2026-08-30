#!/usr/bin/env bash
# omp-preset bootstrap — install this repo's portable omp config/agents/WATCHDOG/
# statusline/plugins/skills into the active omp profile on this machine.
#
# NOT a fork: this copies omp's user-scope dotfiles into place and re-installs
# plugins by reference. It does NOT touch machine-specific state (agent.db OAuth,
# history.db, models.db, sessions, logs, caches) — re-login to your providers after.
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

# 4. statusline script — deployed next to config; ~/.pi/agent/settings.json points at it.
cp "$REPO/statusline.sh" "$AGENT_DIR/statusline.sh"
chmod +x "$AGENT_DIR/statusline.sh"

# 4b. pi settings: merge the statusLine block into ~/.pi/agent/settings.json
#     (the path pi-statusline reads; NOT omp's config.yml). Preserves unknown keys.
PI_SETTINGS="${PI_SETTINGS_PATH:-$HOME/.pi/agent/settings.json}"
if command -v python3 >/dev/null 2>&1; then
  REPO="$REPO" PI_SETTINGS="$PI_SETTINGS" python3 <<'PYEOF'
import json, os

path = os.environ["PI_SETTINGS"]
repo = os.environ["REPO"]
block = {
    "type": "command",
    "command": "~/.omp/agent/statusline.sh",
    "placement": "footer",
    "padding": 0,
    "debounceMs": 300,
    "timeoutMs": 3000,
}
settings = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            settings = json.load(f)
    except Exception:
        settings = {}
if settings.get("statusLine") != block:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path):
        import shutil
        shutil.copy2(path, path + ".preset-bak")
    settings["statusLine"] = block
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print(f"  statusLine -> merged into {path}")
else:
    print(f"  statusLine -> already configured in {path}")
PYEOF
else
  echo "  (warn) python3 not found; add statusLine to $PI_SETTINGS manually:"
  echo '         {"type":"command","command":"~/.omp/agent/statusline.sh","placement":"footer"}'
fi

# 5. PR-description skill — placed so the pr agent's reference resolves.
SKILL_DST="${PR_SKILL_DIR:-$HOME/.agents/skills/writing-pr-descriptions}"
mkdir -p "$SKILL_DST"
cp "$REPO/skills/writing-pr-descriptions/SKILL.md" "$SKILL_DST/SKILL.md"

# 6. plugins — re-installed by reference; never copy node_modules.
if command -v python3 >/dev/null 2>&1 && [[ -f "$REPO/plugins.json" ]]; then
  python3 -c "import json;d=json.load(open('$REPO/plugins.json'));print('\n'.join(p['ref'] for p in d['plugins']))" |
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    case "$ref" in
      "~/"*) ref="$HOME/${ref#\~/}" ;;
    esac
    if [[ "$ref" == /* ]] && [[ ! -d "$ref" ]]; then
      echo "  (skip) missing local source: $ref"
      continue
    fi
    echo "  install: $ref"
    omp plugin install "$ref" || echo "  (warn) plugin install failed: $ref"
  done
fi

echo
echo "Done."
echo "  config     -> $AGENT_DIR/config.yml  (prior saved as .preset-bak)"
echo "  agents     -> $AGENT_DIR/agents/"
echo "  watchdog   -> $AGENT_DIR/WATCHDOG.md"
echo "  statusline -> $AGENT_DIR/statusline.sh (+ statusLine in ~/.pi/agent/settings.json)"
echo "  pr skill   -> $SKILL_DST/SKILL.md"
echo "  plugins    -> reinstalled by ref (optional/missing local ones skipped)"
echo
echo "Notes:"
echo "  - Machine-specific state (agent.db OAuth, history.db, models.db, sessions, logs, caches) was NOT ported."
echo "  - Re-login to your providers before first use, e.g. 'opencode auth login' -> anthropic."
echo "  - If omp changes a config/agent schema in a future release, update this repo (git) and re-run."
