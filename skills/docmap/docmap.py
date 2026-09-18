#!/usr/bin/env python3
# docmap — one-call map of a project's docs by frontmatter, so "read frontmatter first"
# (project-docs) costs ONE call instead of N file reads and beats a blind grep over bodies.
#
# Prints one line per doc:  path · type · status · tags · H1
# Filters (server-side, so the map stays small):  --type X   --tag X   --status X
# Scope: a path arg (default the whole repo). Tracked *.md via git; library infra
#   (.agents/{rules,skills,agents,hooks,templates,generated}) is excluded — .agents/plans/ is kept.
#   Agent ANCHORS (AGENTS.md / CLAUDE.md / GEMINI.md) are pointers, not docs — excluded; symlinks are
#   skipped (so a CLAUDE.md -> AGENTS.md link is not counted twice).
#
# Conformance (mechanical, no interpretation — both catch a SILENTLY-lying tool):
#   - a doc with NO frontmatter is invisible to --type/--tag/--status → the filter lies without a signal;
#   - a dangling relative link (a [text](path) whose target file does not exist) → a broken reference.
# They print to STDERR (the map on stdout stays usable); `--check` makes them exit 1 (linter / gate mode).
import os
import re
import subprocess
import sys

ANCHORS = {"AGENTS.md", "CLAUDE.md", "GEMINI.md"}
EXCLUDE_DIRS = {"node_modules", ".git", ".venv", "venv", "dist", "build", ".astro", ".wrangler",
                ".codegraph", ".docindex", "__pycache__"}
FM = re.compile(r'^---\s*\n(.*?)\n---\s*\n?', re.S)
LINK = re.compile(r'\[[^\]]*\]\(([^)]+)\)')            # [text](target) and ![alt](target)


def keep(p):
    if os.path.basename(p) in ANCHORS:                # agent pointer file, not a project doc
        return False
    parts = p.replace("\\", "/").split("/")
    if ".agents" in parts:                            # library infra copy — except plans/
        i = parts.index(".agents")
        return i + 1 < len(parts) and parts[i + 1] == "plans"
    return True


def md_files(root):
    root = os.path.normpath(root)
    files = []
    try:
        out = subprocess.run(["git", "ls-files", "*.md"], capture_output=True, text=True)
        if out.returncode == 0:
            files = [f for f in out.stdout.splitlines() if f]
    except Exception:
        files = []
    if not files:                                     # not a git repo / nothing tracked → walk
        for dp, dn, fn in os.walk(root):
            dn[:] = [d for d in dn if d not in EXCLUDE_DIRS]
            for f in fn:
                if f.endswith(".md"):
                    files.append(os.path.join(dp, f))
    if root != ".":                                   # scope to the given path prefix
        files = [f for f in files
                 if os.path.normpath(f) == root or os.path.normpath(f).startswith(root + os.sep)]
    return sorted(f for f in files if keep(f) and not os.path.islink(f))


def parse_fm(block):
    d = {"type": "", "status": "", "tags": []}
    lines = block.splitlines()
    i = 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r'^(type|status|project)\s*:\s*(.*)$', ln)
        if m:
            d[m.group(1)] = m.group(2).strip().strip('"\'')
        mt = re.match(r'^tags\s*:\s*(.*)$', ln)
        if mt:
            val = mt.group(1).strip()
            if val.startswith('['):
                d["tags"] = [t.strip().strip('"\'') for t in val.strip('[]').split(',') if t.strip()]
            elif val:
                d["tags"] = [t.strip().strip('"\'') for t in re.split(r'[,\s]+', val) if t.strip()]
            else:
                j = i + 1
                while j < len(lines) and re.match(r'^\s*-\s+', lines[j]):
                    d["tags"].append(re.sub(r'^\s*-\s+', '', lines[j]).strip().strip('"\''))
                    j += 1
                i = j - 1
        i += 1
    return d


def parse(path):
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except Exception:
        return None
    m = FM.match(text)
    if m:
        d = parse_fm(m.group(1))
        d["has_fm"] = True
        body = text[m.end():]
    else:
        d = {"type": "", "status": "", "tags": [], "has_fm": False}
        body = text
    h1 = ""
    for ln in body.splitlines():
        s = ln.strip()
        if s.startswith("# "):
            h1 = s[2:].strip()
            break
    d["h1"] = h1
    d["body"] = body
    return d


def dangling(path, body):
    out = []
    base = os.path.dirname(path)
    for m in LINK.finditer(body):
        raw = m.group(1).strip()
        if not raw:
            continue
        tgt = raw.split()[0]                          # drop a ` "title"` suffix
        if re.match(r'^(https?:|mailto:|tel:|#|/|data:)', tgt):
            continue
        tgt = tgt.split('#', 1)[0].split('?', 1)[0].strip()
        if not tgt:
            continue
        if not os.path.exists(os.path.normpath(os.path.join(base, tgt))):
            out.append(tgt)
    return out


def main():
    args = sys.argv[1:]
    check = "--check" in args
    args = [a for a in args if a != "--check"]
    ftype = ftag = fstatus = None
    root = "."
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--type" and i + 1 < len(args):
            ftype = args[i + 1]
            i += 2
        elif a == "--tag" and i + 1 < len(args):
            ftag = args[i + 1]
            i += 2
        elif a == "--status" and i + 1 < len(args):
            fstatus = args[i + 1]
            i += 2
        else:
            root = a
            i += 1

    missing, broken, rows = [], [], []
    for f in md_files(root):
        info = parse(f)
        if info is None:
            continue
        if not info["has_fm"]:
            missing.append(f)
        d = dangling(f, info["body"])
        if d:
            broken.append((f, d))
        if ftype and info["type"] != ftype:
            continue
        if fstatus and info["status"] != fstatus:
            continue
        if ftag and ftag not in info["tags"]:
            continue
        rows.append((f, info["type"] or "-", info["status"] or "-",
                     ",".join(info["tags"]) or "-", info["h1"] or "-"))

    for f, t, s, tg, h1 in rows:
        print(f"{f} · {t} · {s} · {tg} · {h1}")

    if missing:
        print(f"\n[docmap] {len(missing)} doc(s) with NO frontmatter — invisible to "
              f"--type/--tag/--status (the filter lies without a signal):", file=sys.stderr)
        for f in missing:
            print(f"  {f}", file=sys.stderr)
    if broken:
        n = sum(len(d) for _, d in broken)
        print(f"\n[docmap] {n} dangling link(s) in {len(broken)} doc(s) — target file missing:",
              file=sys.stderr)
        for f, d in broken:
            for t in d:
                print(f"  {f} -> {t}", file=sys.stderr)
    if check and (missing or broken):
        sys.exit(1)


if __name__ == "__main__":
    main()
