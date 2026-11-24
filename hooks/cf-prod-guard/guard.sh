#!/usr/bin/env bash
# cf-prod-guard — ASK for confirmation on MUTATING production Cloudflare ops (approval prompt, not a
# hard block). PreToolUse hook (matcher "Bash"). A hook cannot remember a past approval — it fires on
# EVERY matching call — so it gates only genuine MUTATIONS (rare, consequential), and lets read-only
# prod ops through untouched (routine `d1 execute --remote "SELECT ..."` / `migrations list --remote`
# no longer prompt). Default prod path is still CI (push -> .github/workflows/deploy.yml).
cmd="$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)" || exit 0
[ -n "$cmd" ] || exit 0

mutating=no
# Always mutating: deploy (Worker `wrangler deploy`, `versions deploy`, `pages deploy`), remote migration apply, secret put|delete.
if printf '%s' "$cmd" | grep -qE 'wrangler([[:space:]]+(pages|versions))?[[:space:]]+deploy|wrangler[[:space:]]+d1[[:space:]]+migrations[[:space:]]+apply.*--remote|wrangler([[:space:]]+pages)?[[:space:]]+secret[[:space:]]+(put|delete)'; then
  mutating=yes
  # `deploy --dry-run` builds only, mutates nothing -> not gated.
  if printf '%s' "$cmd" | grep -qE 'wrangler[[:space:]]+(pages[[:space:]]+)?deploy' && printf '%s' "$cmd" | grep -qE -- '--dry-run'; then mutating=no; fi
# d1 execute --remote: gate ONLY a write (SQL DML/DDL or a --file). A read-only SELECT/PRAGMA passes.
elif printf '%s' "$cmd" | grep -qE 'wrangler[[:space:]]+d1[[:space:]]+execute.*--remote' \
   && printf '%s' "$cmd" | grep -qiE '(^|[^a-z])(insert|update|delete|drop|alter|create|replace|truncate)([^a-z]|$)|--file'; then
  mutating=yes
fi

if [ "$mutating" = yes ]; then
  # --deny: hard block (exit 2) for an agent that ignores "ask" (kimi — measured; like opencode).
  if [ "${1:-}" = --deny ]; then
    echo "cf-prod-guard: MUTATING production Cloudflare op blocked (deploy / d1 --remote write / migrations apply --remote / secret put|delete). Default prod path is CI (push -> deploy.yml); the owner runs it manually." >&2
    exit 2
  fi
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"MUTATING production Cloudflare op (deploy / d1 --remote write / migrations apply --remote / secret put|delete). Approve or deny. Read-only d1 --remote is NOT gated. Default prod path is CI (push -> deploy.yml)."}}
JSON
fi
exit 0
