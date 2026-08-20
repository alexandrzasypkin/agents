#!/usr/bin/env bash
# no-git-add-all — PreToolUse hook. GOAL: force EXPLICIT pathspecs in staging (git-discipline).
# A blanket `git add .` / `git add -A` / `git commit -a` stages whatever happens to be dirty —
# the incident where an unrelated file (real names, a secret, a scratch file) rode into a commit
# nobody meant to make. The rule asks for explicit paths; this hook guarantees it.
#   DENY  - git add with -A/--all, -u/--update, or a pathspec of . / :/ / : / *  (stage-everything)
#   DENY  - git commit with -a/--all                                             (stage-everything)
#   ALLOW - git add <explicit paths>, git add -p, and everything else
# Mode: --claude (exit 2 + stderr) | --codex (JSON permissionDecision deny).
# python3 absent -> fail-open (ALLOW).
[ -n "${AGENTS_DEBUG:-}" ] && set -x   # opt-in trace: AGENTS_DEBUG=1
mode="${1:---claude}"
# shellcheck disable=SC2016  # the python body is intentionally single-quoted — bash must NOT expand it.
verdict="$(python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
except Exception:
    print("ALLOW"); sys.exit(0)
ti = d.get("tool_input") or d.get("input") or {}
ti = ti if isinstance(ti, dict) else {}
cmd = str(ti.get("command") or "")
if not cmd:
    print("ALLOW"); sys.exit(0)

# Inspect each shell segment independently (a chain like `cd x && git add .`).
segments = re.split(r"&&|\|\||;|\||\n", cmd)
ALL_TOKENS = {".", ":/", ":", "*", "-A", "--all", "-u", "--update"}

def short_cluster_has(tok, chars):
    # a single-dash cluster like -Av / -uf / -am — does it contain one of chars?
    return bool(re.match(r"^-[^-]", tok)) and any(c in tok[1:] for c in chars)

for seg in segments:
    s = seg.strip()
    m = re.match(r"^(sudo\s+)?git\s+(add|commit)\b(.*)$", s)
    if not m:
        continue
    sub, rest = m.group(2), m.group(3)
    toks = rest.split()
    for t in toks:
        if sub == "add":
            if t in ALL_TOKENS or short_cluster_has(t, "Au"):   # A=--all, u=--update
                print("DENY_ADD:%s" % t); sys.exit(0)
        else:  # commit
            if t in ("-a", "--all") or short_cluster_has(t, "a"):   # -a/-am = stage-all
                print("DENY_COMMIT:%s" % t); sys.exit(0)

print("ALLOW")
' 2>/dev/null)"

case "$verdict" in
  DENY_ADD:*)
    tok="${verdict#DENY_ADD:}"
    msg="no-git-add-all: \`git add $tok\` stages everything dirty — list explicit paths instead (git add path/a path/b). An unrelated/secret/scratch file must not ride into a commit. Override only by naming the paths. See git-discipline." ;;
  DENY_COMMIT:*)
    tok="${verdict#DENY_COMMIT:}"
    msg="no-git-add-all: \`git commit $tok\` stages every modified tracked file — stage explicit paths first (git add path/…; git commit -m …). See git-discipline." ;;
  *) exit 0 ;;
esac

case "$mode" in
  --codex) printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$msg" ;;
  *)       printf '%s\n' "$msg" >&2; exit 2 ;;
esac
exit 0
