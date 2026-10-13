#!/usr/bin/env bash
# git-discipline PreToolUse guard (dir name `no-git-add-all` is historical — the scope is broader now).
# Enforces two MECHANICAL git-discipline invariants at the tool-call boundary — the one local layer an
# agent cannot route around with a git flag, because the harness runs PreToolUse BEFORE git does:
#   1) EXPLICIT staging — no `git add .`/`-A`/`-u`, no `git commit -a` (a stray / secret / scratch file
#      must not ride into a commit nobody meant to make).
#   2) NEVER DISARM THE GATE — no `--no-verify`/`-n`, no `git -c core.hooksPath=<dir>` (a wrong or empty
#      dir runs NO hook, silently), no `git config core.hooksPath`, no `HUSKY=0` env. A mechanism quietly
#      disarmed leaves silence; the gate (secrets, attribution trailer, lint) must actually run.
#   DENY  - the forms above.  ALLOW - git add <explicit paths>, git add -p, plain git commit/push, rest.
# Mode: --claude (exit 2 + stderr) | --codex (JSON permissionDecision deny). python3 absent -> fail-open (ALLOW).
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
    # a single-dash cluster like -Av / -uf / -am / -nm — does it contain one of chars?
    return bool(re.match(r"^-[^-]", tok)) and any(c in tok[1:] for c in chars)

for seg in segments:
    s = seg.strip()
    if not re.search(r"(^|\s)git(\s|$)", s):
        continue

    # (2) never disarm the gate ------------------------------------------------------------------
    if re.search(r"-c\s+[cC]ore\.[hH]ooks[pP]ath\s*=", s):
        print("DENY_BYPASS:git -c core.hooksPath= (points git at another/empty hooks dir - no hook runs)"); sys.exit(0)
    if re.search(r"\bgit\s+config\b[^\n]*[cC]ore\.[hH]ooks[pP]ath", s):
        print("DENY_BYPASS:git config core.hooksPath (persistently redirects the hooks dir)"); sys.exit(0)
    if re.search(r"\bHUSKY=0\b", s):
        print("DENY_BYPASS:HUSKY=0 (disables husky hooks)"); sys.exit(0)
    mcp = re.match(r"^(?:\w+=\S+\s+)*(?:sudo\s+)?git\s+(commit|push)\b(.*)$", s)
    if mcp:
        sub2, rest2 = mcp.group(1), mcp.group(2)
        toks2 = rest2.split()
        if "--no-verify" in toks2:
            print("DENY_BYPASS:--no-verify (skips the commit/push gate)"); sys.exit(0)
        if sub2 == "commit" and ("-n" in toks2 or any(short_cluster_has(t, "n") for t in toks2)):
            print("DENY_BYPASS:-n (git commit -n = --no-verify)"); sys.exit(0)

    # (1) explicit staging -----------------------------------------------------------------------
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
  DENY_BYPASS:*)
    why="${verdict#DENY_BYPASS:}"
    msg="git-discipline: refusing to DISARM the commit gate — $why. Commit with plain \`git commit\`; if a hook is genuinely in the way, say so and FIX the hook — do not route around it. The error is the route around the check, not the thing the check would have caught. (Owner may run it explicitly.)" ;;
  *) exit 0 ;;
esac

case "$mode" in
  --codex) printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$msg" ;;
  *)       printf '%s\n' "$msg" >&2; exit 2 ;;
esac
exit 0
