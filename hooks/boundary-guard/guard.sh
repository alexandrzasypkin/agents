#!/usr/bin/env bash
# boundary-guard — pause writes to boundary-sensitive paths for approval (PreToolUse Write|Edit).
# Role-agnostic: a hook can't see WHICH subagent acts, so it protects PATHS (generated files,
# immutable migrations, server-only dirs), NOT per-role write-zones — those stay the `boundaries`
# rule + lead arbitration. On a match it emits permissionDecision "ask" (approval, not a hard block).
# Config: patterns.conf beside this script, one `<ERE-path><TAB><reason>` per line (blank/# ignored).
# No patterns.conf -> no-op.
here="$(cd "$(dirname "$0")" && pwd)"; conf="$here/patterns.conf"
[ -f "$conf" ] || exit 0
path="$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)" || exit 0
[ -n "$path" ] || exit 0
while IFS=$'\t' read -r pat reason; do
  case "$pat" in ''|\#*) continue;; esac
  if printf '%s' "$path" | grep -qE "$pat"; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"boundary-guard: %s"}}\n' "${reason:-boundary-sensitive path}"
    exit 0
  fi
done < "$conf"
exit 0
