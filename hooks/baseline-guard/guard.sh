#!/usr/bin/env bash
# baseline-guard — PreToolUse hook (GLOBAL): a WRITE to the ~/.agents library needs the
# user's explicit approval. Reading/copying FROM ~/.agents is free.
# On a write it returns permissionDecision "ask", so the agent surfaces the action and YOU
# approve or refuse it natively in the conversation. No env flags — permission is your spoken yes.
[ -n "${AGENTS_DEBUG:-}" ] && set -x
# shellcheck disable=SC2016  # the python program is single-quoted on purpose (no shell expansion)
verdict="$(python3 -c '
import sys,json,os,re
HOME=os.path.expanduser("~"); LIB=os.path.realpath(HOME+"/.agents")
try:
    d=json.load(sys.stdin)
except Exception:
    print("ALLOW"); sys.exit(0)
ti=d.get("tool_input") or d.get("input") or {}; ti=ti if isinstance(ti,dict) else {}
tool=(d.get("tool_name") or d.get("tool") or "").lower()
def under_lib(tok):
    s=tok.replace("$HOME",HOME)
    if s.startswith("~"): s=HOME+s[1:]
    p=os.path.realpath(s)
    return p==LIB or p.startswith(LIB+os.sep)
if tool in ("edit","write","apply_patch","create","str_replace_editor","multiedit"):
    for k in ("file_path","path","filePath"):
        v=ti.get(k)
        if isinstance(v,str) and v and under_lib(v): print("ASK"); sys.exit(0)
    patch=ti.get("patch")
    if isinstance(patch,str):
        for m in re.findall(r"(?m)^\*\*\* (?:Update|Add|Delete) File: (.+)$",patch)+re.findall(r"(?m)^\+\+\+ b/(.+)$",patch):
            if under_lib(m): print("ASK"); sys.exit(0)
cmd=ti.get("command")
if isinstance(cmd,str) and cmd:
    cl=cmd.replace("$HOME",HOME).replace("~",HOME)
    if LIB in cl:
        lib=re.escape(LIB)
        if (re.search(r"\b(rm|rmdir|mv|tee|truncate|chmod|chown|mkdir|ln|shred)\b[^|;&]*"+lib,cl)
            or re.search(r">>?\s*"+lib,cl)
            or re.search(r"\bsed\b[^|;&]*-i[^|;&]*"+lib,cl)
            or re.search(r"\bcp\b\s+\S+\s+"+lib,cl)):
            print("ASK"); sys.exit(0)
print("ALLOW")
' 2>/dev/null)"
[ "$verdict" = ASK ] || exit 0
reason="baseline-guard: this writes to the ~/.agents library (the shared baseline). Approve only if you intend a baseline change. Reading/copying FROM it is free."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
