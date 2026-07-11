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
- Do not push to `main` directly without an explicit request — work via a branch/PR or an
  explicit merge after review.
- Do not skip pre-commit / pre-push hooks without an explicit request.

[CRITICAL] Never `git push --force` on `main`.
[CRITICAL] Never commit secrets (`.env`, `.dev.vars`, tokens) or generated artifacts
(`dist/`, build caches). See `secrets`.
