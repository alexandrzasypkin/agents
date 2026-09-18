---
name: docmap
description: Map a project's docs by frontmatter in ONE call — path · type · status · tags · H1, with --type/--tag/--status filters. Apply BEFORE grepping doc bodies or reading docs to find the right one; the metadata pass this makes cheap is what "read frontmatter first" (project-docs) needs. Also flags docs missing frontmatter and dangling links.
---

# docmap — read frontmatter first, in one call

`project-docs` says **read frontmatter first, filter by `type`/`tags`/`status`, then read only the
relevant body**. The reason it loses to a blind `grep` over bodies is economics, not discipline: the
metadata pass costs N file reads, grep is one call — so the cheap wrong path wins every time. `docmap`
removes that gap: it prints the whole project's doc metadata in **one call**, cheaper than grep and
correct (grep matches a body regardless of `status`, so it walks you into **archived / superseded** docs;
`docmap --status active` does not).

Run it BEFORE reaching for grep to *find which doc*. It is a script in this skill's dir (there is no
`docmap` on PATH) — invoke by path from the repo root (`python3` only, no deps):

```
python3 .agents/skills/docmap/docmap.py                 # every doc: path · type · status · tags · H1
python3 .agents/skills/docmap/docmap.py docs/           # scope to a subtree
python3 .agents/skills/docmap/docmap.py --type spec     # only specs
python3 .agents/skills/docmap/docmap.py --tag onboarding
python3 .agents/skills/docmap/docmap.py --status active # skip archived/superseded (grep can't)
python3 .agents/skills/docmap/docmap.py --check         # exit != 0 on missing-frontmatter / dangling links
```
(From a subdir, resolve the root: `python3 "$(git rev-parse --show-toplevel)/.agents/skills/docmap/docmap.py"`.)

Read the lines, pick the doc, open only that body. Filters combine.

## Conformance (mechanical — both catch a silently-lying tool)
Printed to **stderr** (the map on stdout stays usable); `docmap --check` exits non-zero on either,
so it doubles as a linter / CI gate:

- **docs with NO frontmatter** — invisible to every `--type/--tag/--status` filter, so a filtered
  result is silently incomplete (a `grep -l tag` over a half-marked corpus lies with no error). This is
  the gap `docs-frontmatter` (a save-time nudge) cannot see: files that were *already* lying there
  unmarked.
- **dangling links** — a `[text](path.md)` whose target file does not exist. Unambiguous, checked
  against the current filesystem (not intended meaning), so it never lies. This enforces the
  `project-docs` "exact-path relative links" rule.

Scope: tracked `*.md`; library infra (`.agents/{rules,skills,agents,hooks,templates,generated}`) is
excluded, `.agents/plans/` kept. No external dependencies (`python3` only).

## What docmap is NOT
A **facet filter** (type/status/tags/H1), not a document graph. It does **not** answer "what breaks if I
change this doc" — those links are hand-maintained and lag reality, so a doc-link *graph* would look
authoritative while lying; only the mechanical **dangling-link** check survives that objection. For
impact/where-used across the *code*, that's `code-search` (a graph derived from the code, always current).
