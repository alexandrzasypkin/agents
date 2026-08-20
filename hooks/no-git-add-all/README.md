# no-git-add-all

Deterministic guard for the `git-discipline` "explicit paths in `git add`" rule — *a rule
asks, a hook guarantees*. A blanket stage-everything (`git add .`, `git add -A`, `git commit -a`)
is what let an unrelated file — real names, a secret, a scratch file — ride into a commit nobody
meant to make. The rule is a soft instruction the agent forgets on a long session; this hook fires
mechanically on the tool call.

## What it blocks (agent Bash/tool calls only — never affects a human's own shell)
- `git add` with `-A` / `--all`, `-u` / `--update`, or a pathspec of `.` / `:/` / `:` / `*`
- `git commit` with `-a` / `--all` (`-am`, `-a`, …) — same stage-everything footgun
- Short clusters count: `-Av`, `-uf`, `-am` are caught.

## What passes
- `git add <explicit paths>`, `git add -p` (interactive/patch), `git commit -m …` after an
  explicit `git add`, `git commit --amend` (long flag, not `-a`), and every non-`add`/`commit` git op.

## Files & wiring
- `guard.sh --claude|--codex` — the check (python3 stdin parse; fail-open if python3 is absent).
- `claude.json` / `codex.toml` / `opencode.ts` — per-agent PreToolUse fragments (matcher `Bash`),
  pointing at the project's own copied `guard.sh`. Wired to `git-discipline` in `map.yaml`
  (base → every project gets it). Bootstrap deep-merges the fragment into each agent's config.

Override is by design friction: to stage everything, name the paths. There is no `--no-verify`
for an agent PreToolUse hook — that is the point.
