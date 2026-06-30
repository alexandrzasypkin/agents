#!/usr/bin/env bash
# secrets-guard — PreToolUse hook: block a tool call that reads/writes a secret file.
# Mode: --claude (exit 2 + stderr) | --codex (JSON permissionDecision deny).
# Reads the tool-call JSON on stdin; checks file paths AND shell commands (cross-agent,
# catches e.g. `cat .env`). *.example/.sample/.template are allowed (templates).
# python3 absent -> fail-open (allow); python3 is always present in our baseline.
mode="${1:---claude}"
verdict="$(python3 -c '
import sys,json,re
try:
    d=json.load(sys.stdin)
except Exception:
    print("ALLOW"); sys.exit(0)
ti=d.get("tool_input") or d.get("input") or {}
ti=ti if isinstance(ti,dict) else {}
text=" ".join(str(ti.get(k,"")) for k in ("file_path","path","filePath","command","patch"))
SAFE=("example","sample","template")
def secret(name):
    base=name.rsplit("/",1)[-1].lower()
    if base in (".secrets",".dev.vars",".env"): return True
    if base.endswith(".pem"): return True
    if base.startswith(("id_rsa","id_ed25519")): return True
    if base.startswith(".env.") and base.rsplit(".",1)[-1] not in SAFE: return True
    return False
print("DENY" if any(secret(t) for t in re.findall(r"[\w./-]+",text)) else "ALLOW")
' 2>/dev/null)"
[ "$verdict" = DENY ] || exit 0
msg="secrets-guard: blocked access to a secret file (.env/.dev.vars/.secrets/key). Read keys via a list, never the values. See the secrets rule."
case "$mode" in
  --codex) printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$msg" ;;
  *)       printf '%s\n' "$msg" >&2; exit 2 ;;
esac
exit 0
