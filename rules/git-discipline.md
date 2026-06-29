---
name: git-discipline
description: Git hygiene. Apply in any project under version control.
---

# git-discipline

- Commit after each completed step of a task — small, traceable commits.
- Stage explicit paths (`git add <files>`), not `git add -A` by default — guards against
  committing secrets or generated artifacts.
- Commit message: `<scope>: <imperative summary>`; add a body for details when needed.
- Do not push to `main` directly without an explicit request — work via a branch/PR or an
  explicit merge after review.
- Do not skip pre-commit / pre-push hooks without an explicit request.

[CRITICAL] Never `git push --force` on `main`.
[CRITICAL] Never commit secrets (`.env`, `.dev.vars`, tokens) or generated artifacts
(`dist/`, build caches). See `secrets`.
