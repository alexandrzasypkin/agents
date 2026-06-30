# git-quality-gate

The mandatory git-hook quality gate. The **main** lint/type/test check runs on the git
event, so it cannot be forgotten (see the canon Hooks section + BOOTSTRAP step 5).

## Files
- `gate.sh <commit|push>` — the dispatcher (language detection + checks). Lives in the
  project under `./.agents/hooks/git-quality-gate/` (tracked, editable).
- `pre-commit` / `pre-push` — thin wrappers; bootstrap installs them into `.git/hooks/`
  (not tracked) where they `exec` `gate.sh`.

## What it runs
- **pre-commit** (fast): staged-secret scan + linters for the languages present
  (ruff / eslint|npm-lint / shellcheck / perl -c / g++ -fsyntax-only).
- **pre-push** (full): the above + type-check (pyright / tsc) + tests (pytest / npm test).

Checks follow the `quality-*` rules. A missing tool is reported and skipped, not fatal
(install-when-needed is a project decision — see `env-setup`). A real failure exits 2 and
blocks the git operation.

## Install (bootstrap, mandatory)
Copy `pre-commit` and `pre-push` into `.git/hooks/` and `chmod +x` them; keep `gate.sh`
in `./.agents/hooks/git-quality-gate/`. Unconditional — not a survey option.
