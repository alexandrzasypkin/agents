# agents-md-guard

Keeps the project `AGENTS.md` a **pointer**, not a rule store. Agents re-derive a rule they already
have a home for and dump it into the lessons block; the **author is blind to its own duplication**, so
the soft "it's a leak — move it" instruction fails (once it took three human nudges to get a dedup).
*A rule asks, a hook guarantees.*

This hook enforces the **deterministic** half — a hard cap on the lessons block, so growth forces a
triage decision at the exact moment of writing (the blind spot). It does **not** dedup semantically
(a line that duplicates a rule but sits under the cap slips it) — that is the job of a later headless
reviewer mode. C bounds *quantity*; A (semantic) bounds *duplication*.

## The marker + cap
The lessons block is delimited; the cap rides on the start marker (raising it is a deliberate,
visible act — log it in `REGISTRY.md`):
```
<!-- lessons:start max=12 -->
- **[lesson]** …
- **[lesson]** …
<!-- lessons:end -->
```
- Cap counts **top-level `- ` bullets** between the markers. `max=` omitted → default **12**.
- **No markers → the guard is inert** (ALLOW). Bootstrap's template ships them; an existing project
  is migrated by wrapping its lessons block once.

## What it blocks (PreToolUse `Write|Edit`, `AGENTS.md` only)
Blocks **only** an edit that **adds** a bullet while at/over the cap. Deliberately narrow:
- an unrelated edit (bullet count unchanged) → passes, even if the block is already over cap;
- a **dedup** edit (count goes down) → always passes;
- so a legacy over-cap block never traps unrelated work — only *growth* is stopped.

The hook recomputes the resulting file (Write: the new content; Edit: `old_string`→`new_string`
applied to the on-disk file) and counts the block there.

## Files & wiring
- `lessons-cap.sh --claude|--codex` — the check (python3 stdin parse; fail-open if python3 absent).
- `claude.json` / `codex.toml` / `opencode.ts` — per-agent PreToolUse fragments (matcher `Write|Edit`).
  Wired to `project-docs` in `map.yaml` (base → every project).

## Known gaps
- **codex `apply_patch`** carries a diff blob, not `file_path`/`content` — the script can't
  reconstruct the result, so that path is **not covered** (fail-open). Direct Write/Edit is covered.
- A write via **Bash** (`echo >> AGENTS.md`) bypasses a file-tool matcher. Agents don't edit the
  anchor that way; add a pre-commit backstop only if it proves a real problem (canon: after an
  incident, not speculatively).
