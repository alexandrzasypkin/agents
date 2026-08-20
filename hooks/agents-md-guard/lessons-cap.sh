#!/usr/bin/env bash
# agents-md-guard / lessons-cap — PreToolUse (Write|Edit) hook on AGENTS.md.
# GOAL: keep the anchor a POINTER, not a rule store. Agents re-derive a rule they already have a
# home for and dump it into the lessons block; the author is blind to its own duplication, so the
# soft "it's a leak, move it" rule fails (it took three human nudges once). This hook can't dedup
# semantically (that's the headless reviewer, a later mode) — it enforces the DETERMINISTIC half:
# a hard cap on the lessons block, so growth forces triage at the exact moment of writing.
#
# The lessons block is delimited by markers; the cap rides on the start marker (raising it is a
# deliberate, visible act — log it in REGISTRY):
#   <!-- lessons:start max=12 -->
#   ... - bullets ...
#   <!-- lessons:end -->
# No markers -> guard is inert (ALLOW). Blocks ONLY when this edit ADDS a bullet while over the cap:
# an unrelated edit (count unchanged) or a dedup edit (count down) always passes, even over cap.
# Mode: --claude (exit 2 + stderr) | --codex (JSON deny). python3 absent -> fail-open (ALLOW).
[ -n "${AGENTS_DEBUG:-}" ] && set -x   # opt-in trace: AGENTS_DEBUG=1
mode="${1:---claude}"
# shellcheck disable=SC2016  # python body intentionally single-quoted — bash must NOT expand it.
verdict="$(python3 -c '
import sys, json, re, os
try:
    d = json.load(sys.stdin)
except Exception:
    print("ALLOW"); sys.exit(0)
ti = d.get("tool_input") or d.get("input") or {}
ti = ti if isinstance(ti, dict) else {}
fp = str(ti.get("file_path") or ti.get("path") or ti.get("filePath") or "")
if os.path.basename(fp) != "AGENTS.md":
    print("ALLOW"); sys.exit(0)

try:
    with open(fp, "r", encoding="utf-8") as f:
        before = f.read()
except Exception:
    before = ""

content = ti.get("content")
if content is not None:                       # Write: content is the whole new file
    after = str(content)
else:                                         # Edit: apply old_string -> new_string to the file
    old = str(ti.get("old_string") or "")
    new = str(ti.get("new_string") or "")
    if not old:
        print("ALLOW"); sys.exit(0)
    after = before.replace(old, new) if ti.get("replace_all") else before.replace(old, new, 1)

START = re.compile(r"<!--\s*lessons:start(?:\s+max=(\d+))?\s*-->", re.I)
END   = re.compile(r"<!--\s*lessons:end\s*-->", re.I)
def block(text):
    m = START.search(text)
    if not m: return None
    e = END.search(text, m.end())
    if not e: return None
    n  = len(re.findall(r"(?m)^-\s", text[m.end():e.start()]))   # top-level dash bullets
    mx = int(m.group(1)) if m.group(1) else 12                   # default cap if marker omits max=
    return n, mx

bi = block(after)
if not bi:                                    # no markers -> nothing to enforce
    print("ALLOW"); sys.exit(0)
after_n, mx = bi
b = block(before)
before_n = b[0] if b else 0
# Block ONLY a change that adds a bullet while at/over the cap.
if after_n > mx and after_n > before_n:
    print("DENY:%d:%d:%d" % (before_n, after_n, mx)); sys.exit(0)
print("ALLOW")
' 2>/dev/null)"

case "$verdict" in
  DENY:*)
    IFS=: read -r _ bn an mx <<<"$verdict"
    msg="agents-md-guard: the AGENTS.md lessons block is capped at max=$mx bullets (this edit takes it $bn->$an). The anchor is a POINTER, not a rule store — merge or drop a line whose home is a rule/REGISTRY/docs, or raise max= on the <!-- lessons:start --> marker with a REGISTRY note. Canon: lessons are incident-driven and lean." ;;
  *) exit 0 ;;
esac

case "$mode" in
  --codex) printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$msg" ;;
  *)       printf '%s\n' "$msg" >&2; exit 2 ;;
esac
exit 0
