#!/usr/bin/env bash
# commit-msg gate — reject AI/tool ATTRIBUTION trailers in the commit message.
# Canon "no-noise commits" (git-discipline): traceability belongs in the code/plan, not in a
# "Co-Authored-By: <bot>" / "Generated with <tool>" trailer. This is deterministic because the
# soft rule loses to a baked-in habit (Claude Code auto-appends the trailer) — the hook is the
# reliable stop. $1 = commit-message file. Exit 1 blocks the commit.
set -uo pipefail
msg_file="${1:?commit-msg: no message file}"
[ -f "$msg_file" ] || exit 0

# Drop git's helper/comment lines (default commentChar '#') before matching the real message.
body="$(grep -v '^[[:space:]]*#' "$msg_file")"

hits=""
printf '%s\n' "$body" | grep -qiE '^[[:space:]]*Co-Authored-By:' \
  && hits="Co-Authored-By: trailer"
printf '%s\n' "$body" | grep -qiE 'Generated (with|by)' \
  && hits="${hits:+$hits; }\"Generated with/by\" attribution"

if [ -n "$hits" ]; then
  {
    echo "commit-msg: BLOCK - attribution/noise trailer in the message ($hits)."
    echo "  canon no-noise commits (git-discipline): no AI/tool attribution in the message."
    echo "  Remove it and re-commit. A project that genuinely needs the trailer overrides this hook."
  } >&2
  exit 1
fi
exit 0
