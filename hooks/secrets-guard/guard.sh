#!/usr/bin/env bash
# secrets-guard — PreToolUse hook. GOAL: a secret VALUE must never reach the chat/transcript.
# It is NOT a blanket ban on touching secret files — the `secrets` rule explicitly sanctions using a
# value through a PIPE (`grep ^KEY= .dev.vars | cut -d= -f2- | <consumer>`), and `cf-secrets` is built
# on it. So this blocks only what would surface the value:
#   DENY  - Read/Write/Edit tool on a secret file (Read returns content; Write/Edit carries the value)
#   DENY  - a Bash command whose STDOUT would carry the content (bare `cat/head/tail/grep .env`,
#           or a pipeline ending in a printer)
#   ALLOW - the pipeline/redirect pattern (value flows into a consumer or a file, never to stdout)
#   ALLOW - metadata-only ops that never print content (ls, stat, test, wc, cp, mv, rm, chmod, git, shred)
# Mode: --claude (exit 2 + stderr) | --codex (JSON permissionDecision deny).
# *.example/.sample/.template are always allowed (templates). python3 absent -> fail-open.
[ -n "${AGENTS_DEBUG:-}" ] && set -x   # opt-in trace: AGENTS_DEBUG=1
mode="${1:---claude}"
# shellcheck disable=SC2016  # the python body is intentionally single-quoted — bash must NOT expand $1/$2 etc.
verdict="$(python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
except Exception:
    print("ALLOW"); sys.exit(0)
ti = d.get("tool_input") or d.get("input") or {}
ti = ti if isinstance(ti, dict) else {}
fp    = str(ti.get("file_path") or ti.get("path") or ti.get("filePath") or "")
cmd   = str(ti.get("command") or "")
patch = str(ti.get("patch") or "")

SAFE = ("example", "sample", "template")
def secret(name):
    base = name.rsplit("/", 1)[-1].lower()
    if base in (".secrets", ".dev.vars", ".env"): return True
    if base.endswith(".pem"): return True
    if base.startswith(("id_rsa", "id_ed25519")): return True
    if base.startswith(".env.") and base.rsplit(".", 1)[-1] not in SAFE: return True
    return False
def has_secret(text):
    return any(secret(t) for t in re.findall(r"[\w./-]+", text))

# 1) File tools on a secret file: Read leaks the content, Write/Edit carries the value. Hard deny.
if (fp and secret(fp)) or (patch and has_secret(patch)):
    print("DENY_FILE"); sys.exit(0)

# 2) Shell: block only when the secret content would land on STDOUT (-> transcript).
if cmd and has_secret(cmd):
    META = r"^(sudo\s+)?(ls|stat|test|\[|wc|du|find|chmod|chown|cp|mv|rm|touch|mkdir|shred|git)\b"
    if re.match(META, cmd.strip()):
        print("ALLOW"); sys.exit(0)                 # never prints file content
    last = cmd.split("|")[-1].strip()               # only the FINAL stage reaches stdout
    # Provably non-printing final stages -> ALLOW: exit-code/count only, or key NAMES only (never
    # values). FAIL-CLOSED: a near-miss variant (cut -f1,2 / -f2- / awk $2 / grep without -q|-c)
    # does NOT match and falls through to DENY. Deliberately not "ask": approving such a command
    # runs it, and its stdout is already in the transcript — the leak would be irreversible.
    SAFE_FINAL = (r"^(sudo\s+)?(grep\s+-\w*[qc]\w*\s"
                  r"|cut\s+-d=\s+-f1(\s|$)"
                  r"|awk\s+-F=\s*[^{]*\{\s*print\s+\$1\s*\})")
    if re.match(SAFE_FINAL, last):
        print("ALLOW"); sys.exit(0)
    # anything that echoes its input onward (incl. text filters) would surface the value
    PRINTER = (r"^(sudo\s+)?(cat|head|tail|less|more|bat|xxd|od|strings|nl|tac|tee|echo|printf"
               r"|grep|egrep|fgrep|rg|sed|awk|cut|tr|sort|uniq|rev|fold|paste|column|jq|yq|base64)\b")
    if ">" in last:
        print("ALLOW"); sys.exit(0)                 # redirected to a file — never hits stdout
    if "|" in cmd and not re.match(PRINTER, last):
        print("ALLOW"); sys.exit(0)                 # sanctioned pipeline ending in a consumer
    print("DENY_STDOUT"); sys.exit(0)

print("ALLOW")
' 2>/dev/null)"

case "$verdict" in
  DENY_FILE)   msg="secrets-guard: a secret file may not be opened/written with a file tool (the value would enter the transcript). Use it through a pipe instead: grep '^KEY=' <file> | cut -d= -f2- | <consumer>. See the secrets rule." ;;
  DENY_STDOUT) msg="secrets-guard: that command would print a secret value to stdout (i.e. into the chat). Pipe it into a consumer or redirect it to a file: grep '^KEY=' <file> | cut -d= -f2- | <consumer>. See the secrets rule." ;;
  *) exit 0 ;;
esac

case "$mode" in
  --codex) printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$msg" ;;
  *)       printf '%s\n' "$msg" >&2; exit 2 ;;
esac
exit 0
