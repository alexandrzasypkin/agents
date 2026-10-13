# no-git-add-all

Deterministic PreToolUse guard for `git-discipline` — *a rule asks, a hook guarantees*. The directory
name is historical: it started as the "explicit paths in `git add`" guard and now enforces **two**
mechanical git invariants at the tool-call boundary — the one local layer an agent cannot route around
with a git flag, because the harness runs PreToolUse *before* git does.

## What it blocks (agent Bash/tool calls only — never a human's own shell)

**1. Stage-everything** (a stray / secret / scratch file must not ride into a commit nobody meant to make):
- `git add` with `-A` / `--all`, `-u` / `--update`, or a pathspec of `.` / `:/` / `:` / `*`
- `git commit` with `-a` / `--all`
- short clusters count: `-Av`, `-uf`, `-am` are caught.

**2. Disarming the commit gate** (a mechanism quietly disarmed leaves silence — the gate for secrets,
the attribution trailer, and lint must actually run):
- `--no-verify` on `git commit` / `git push`, and `-n` on `git commit` (= `--no-verify`)
- `git -c core.hooksPath=<dir>` — points git at another or empty hooks dir, so NO hook runs
- `git config core.hooksPath …` — the persistent form of the same redirect
- `HUSKY=0` env — disables husky-managed hooks

## What passes
- `git add <explicit paths>`, `git add -p`, `git commit -m …` after an explicit `git add`,
  `git commit --amend`, plain `git push`, `git push -n` (dry-run, not a bypass),
  `git -c user.name=… commit` (a non-hooksPath `-c`), and every other git op.

## Files & wiring
- `guard.sh --claude|--codex` — the check (python3 stdin parse; fail-open if python3 is absent).
- `claude.json` / `codex.toml` / `opencode.ts` — per-agent PreToolUse fragments (matcher `Bash`),
  pointing at the project's own copied `guard.sh`. Wired to `git-discipline` in `map.yaml`
  (base → every project gets it). Bootstrap deep-merges the fragment into each agent's config.

Override is by design friction: to stage everything, name the paths; to skip the gate, don't — fix the
hook instead (an owner may run the command themselves). There is no `--no-verify` for an agent, by design.
The remote (pre-receive / CI) is the only backstop a local bypass cannot reach.
