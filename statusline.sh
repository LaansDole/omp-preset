#!/bin/sh
# omp-preset statusline — Claude Code-compatible statusline command for pi-statusline.
# Receives a JSON payload on stdin (see pi-statusline payload contract) and prints
# one statusline:  model | ctx% + context zone | session cost | git branch/state.
#
# Context zones (idea from r/PiCodingAgent "statusline-pi"): tell you when there
# is room to code, when to wrap up, and when to start a new session.
#
# Tunables:
CODE_ZONE_MAX=59      # <= this % used  -> plenty of room
WRAP_ZONE_MAX=84      # <= this % used  -> wrap up current task
# always exit 0 — a non-zero exit makes pi-statusline render nothing.

# ---- read payload (tolerate empty/missing stdin) ----
payload="$(cat 2>/dev/null || true)"

if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  model="$(printf '%s' "$payload" | jq -r '.model.display_name // .model.id // "omp"' 2>/dev/null)"
  pct="$(printf '%s' "$payload" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)"
  cost="$(printf '%s' "$payload" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)"
else
  model="omp"; pct=""; cost=""
fi

# ---- context zone ----
zone=""; zone_color="32"   # 32=green 33=yellow 31=red (ANSI fg)
if [ -n "$pct" ] && [ "$pct" != "null" ]; then
  case "$pct" in
    ''|*[!0-9]*) pct_int="" ;;
    *) pct_int="$pct" ;;
  esac
  if [ -n "$pct_int" ]; then
    if [ "$pct_int" -le "$CODE_ZONE_MAX" ]; then
      zone="code"; zone_color="32"
    elif [ "$pct_int" -le "$WRAP_ZONE_MAX" ]; then
      zone="wrap up"; zone_color="33"
    else
      zone="NEW SESSION"; zone_color="31"
    fi
  fi
fi

# ---- git (cwd = workspace dir; guard non-repo) ----
git_part=""
if command -v git >/dev/null 2>&1; then
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  if [ -n "$branch" ]; then
    dirty=""
    n="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    [ "${n:-0}" -gt 0 ] 2>/dev/null && dirty="*"
    git_part=" ${C_RESET}┃ ${C_DIM}${branch}${dirty}${C_RESET}"
  fi
fi

# ---- ANSI helpers (extension strips these when measuring width) ----
ESC="$(printf '\033')"
C_RESET="${ESC}[0m"; C_DIM="${ESC}[2m"; C_BOLD="${ESC}[1m"
C_ZONE="${ESC}[${zone_color}m"; C_MODEL="${ESC}[35m"; C_CTX="${ESC}[36m"; C_COST="${ESC}[33m"

# ---- compose ----
out="${C_MODEL}${model}${C_RESET}"
if [ -n "$pct_int" ]; then
  out="${out} ${C_RESET}┃ ${C_CTX}ctx ${pct}%${C_RESET} ${C_ZONE}[${zone}]${C_RESET}"
fi
case "$cost" in
  ""|null|0) ;;
  *) out="${out} ${C_RESET}┃ ${C_COST}\$${cost}${C_RESET}" ;;
esac
out="${out}${git_part}"

printf '%s' "$out"
exit 0
