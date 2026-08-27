# git-quality-gate

The mandatory git-hook quality gate. The **main** lint/type/test check runs on the git
event, so it cannot be forgotten (see `~/.agents/bootstrap.md` — the Hooks section + BOOTSTRAP step 5).

## Files
- `gate.sh <commit|push>` — the dispatcher (language detection + checks). Lives in the
  project under `./.agents/hooks/git-quality-gate/` (tracked, editable).
- `msg-gate.sh <msgfile>` — the commit-message gate (attribution-trailer reject). Tracked, editable.
- `pre-commit` / `pre-push` / `commit-msg` — thin wrappers; bootstrap installs them into `.git/hooks/`
  (not tracked) where they `exec` the tracked gate.

## What it runs
- **pre-commit** (fast): staged-secret scan + linters for the languages present
  (ruff / eslint|npm-lint / `bash -n` + shellcheck / perl -c / g++ -fsyntax-only).
- **commit-msg**: rejects AI/tool **attribution trailers** — `Co-Authored-By:` or `Generated with/by`
  (canon no-noise commits / `git-discipline`). Deterministic on purpose: it overrides a host CLI that
  auto-appends the trailer. A project that genuinely needs it overrides `msg-gate.sh`.
- **pre-push** (full): the above linters + type-check (pyright / tsc) + tests (pytest / npm test).

The **secret scan is built-in (grep) and unconditional** — it is NEVER skip-if-missing
(secrets are base/[CRITICAL]); it catches staged secret files and private-key material, and
external scanners like `gitleaks` only *add* to it, never replace it. The **linters /
type-check / tests** follow the `quality-*` rules and ARE skip-if-missing — a missing tool
is reported, not fatal (install-when-needed — see `env-setup`). A real failure exits 2 and
blocks the git operation.

## Install (bootstrap, mandatory)
Copy `pre-commit`, `pre-push` and `commit-msg` into `.git/hooks/` and `chmod +x` them; keep
`gate.sh` and `msg-gate.sh` in `./.agents/hooks/git-quality-gate/`. Unconditional — not a survey option.

## Verifying a change to the gate — testing `gate.sh` directly is NOT enough
The gate judges by its own exit code, so a bug that makes it silently **skip** its checks — or that
breaks git itself — looks identical to a clean pass: it prints `ok` and does nothing. Two real incidents
(2026-08-25) shared this signature: reading the pre-push stdin broke `git push` on ssh (SIGPIPE, nothing
sent); a dangling `@{u}` made `git diff` output empty, so `scoped()` saw no files and skipped everything.
**Both were invisible from inside the gate** — *failure looks like success*.

So invoking `gate.sh commit|push` directly only exercises the gate's own logic; it cannot catch this
class. Verify a change the one honest way (proof-loop: an independent check, not the tool's own verdict):
run a **real `git commit` / `git push`** through the installed hook, then confirm from **outside** — did
the commit/push actually land (`git log origin/<branch>`), and did the checks you expected actually run
(their `+ <cmd>` lines in stderr)?
