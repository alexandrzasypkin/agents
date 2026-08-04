---
name: git-discipline
description: Git hygiene. Apply in any project under version control.
---

# git-discipline

- **Orient before you act — verify state, never assume it.** Before ANY git operation, check the current
  branch (`git branch --show-current`), `git status`, and recent log. On a remote / multi-session /
  multi-machine repo the state **drifts between sessions**: a branch gets merged & deleted elsewhere, new
  uncommitted work appears, origin moves. Never carry a prior session's assumption about "which branch" or
  "what's committed" — re-check first. (Committing to the wrong branch because you assumed stale state is a
  real, avoidable mistake.)
- **Keep git actual, especially on a remote.** `git fetch` to see where origin is; surface ahead/behind and
  any uncommitted work; commit promptly (below). Stale local state on a shared remote is what causes
  wrong-branch commits and merge confusion — don't let it drift. (Pushing stays the user's call, but **flag
  when a push is due**.)
- **Commit after each completed unit of plan/task work — MANDATORY, do NOT ask.** Git is cheap; the
  commit IS the checkpoint (the plan-step boundary / handoff point), so "should I commit?" is noise —
  just commit. Small, traceable commits. (**Pushing** is different — it still needs an explicit go; see below.)
- Stage explicit paths (`git add <files>`), not `git add -A` by default — guards against
  committing secrets or generated artifacts.
- Commit message: Conventional Commits — `<type>(<scope>): <imperative summary>`, where
  `type` ∈ feat / fix / docs / refactor / test / chore / perf. Body explains **why** (not
  what — the diff shows what) when non-trivial; footer for refs / trailers. **No emoji.**
- [CRITICAL] **Only the essence. Hard cap: subject ≤ 72 chars, body ≤ 5 lines.** The message is read
  later by someone scanning history — not a report on how the change came about. Everything below
  belongs in `docs/` or the plan, NEVER in the message:
  - provenance — who or what found it (a review, an agent, an article, a colleague project), dates of
    incidents, links to sources;
  - the investigation — what was tried, which hypothesis failed, how long it took;
  - restating the diff, listing touched files, quoting gate output ("lint ✓ typecheck ✓").
  Keep exactly: what changed, and the non-obvious why in one or two sentences. If the why needs more,
  write it in the doc and reference nothing — the doc is findable by the pointer. *Test before
  committing:* strike every sentence that would not change a reader's decision when they hit this commit
  in `git log` or `git blame`. If the body survives at 2-3 lines, it was right.
- Do not push to `main` directly without an explicit request — work via a branch/PR or an
  explicit merge after review.
- Do not skip pre-commit / pre-push hooks without an explicit request.

[CRITICAL] Never `git push --force` on `main`.
[CRITICAL] Never commit secrets (`.env`, `.dev.vars`, tokens) or generated artifacts
(`dist/`, build caches). See `secrets`.
