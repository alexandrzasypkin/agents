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
- **Identity is part of that state — "not found" is a question, not a verdict.** A host CLI (`gh`, and
  friends) can hold **several** authenticated accounts, and the *active* one may simply lack access to a
  private repo. The API then answers `404 / could not resolve repository` — indistinguishable from "does
  not exist", so it is routinely misread as "no access exists" and the check gets skipped entirely. Before
  concluding anything is unreachable, ask **who am I** (`gh auth status`) and switch if needed
  (`gh auth switch --hostname <host> --user <who>`). Switching is **machine-global** — it changes every
  other project on the box, so say so, record it, and put it back if it was not yours to change.
- **A repo can push to more than one remote, and "I pushed" ≠ "it arrived where CI / the reviewer looks".**
  `git remote -v` may list several remotes/URLs; a workflow fires, or a reviewer sees a branch, only on the
  remote they actually watch. Verify the ref landed where it must (`git ls-remote <remote-or-url> <ref>`),
  not just that `git push` printed something.
- **A multi-pushurl remote pushes to each URL in listed ORDER, and the failure modes differ.** A non-ff
  **rejection** fails just that URL (exit 1) while earlier URLs already landed — buried among success lines,
  so a **non-zero exit after an apparently-successful push is the detector**; never read only the last line.
  An **unreachable** URL is worse: git `die()`s (exit 128) at that point and **never tries the URLs listed
  after it** — so a dead mirror wedges the push, and a dead mirror listed FIRST means nothing lands at all.
  No one can guarantee a mirror never dies, so the fix is not to block harder (git already over-blocks) but
  to order and prune: put the **authoritative URL first** (it lands even if a later mirror is dead), and
  **remove a permanently-dead pushurl** — git will not route around it. Because the exit code alone can't
  tell "all landed" from "a later mirror died", after any such push verify each URL — `git remote get-url
  --push --all <remote>`, then `git ls-remote <url> <ref>` vs `git rev-parse <ref>`. On a mismatch:
  **ahead/diverged** (remote has commits you lack) → fetch/merge/re-push that URL; **behind but reachable**
  → the remote DECLINED (e.g. a pre-receive hook or branch protection), satisfy the gate, don't fetch/merge;
  **unreachable** → infrastructure, fix or drop the mirror.
- **Keep git actual, especially on a remote.** `git fetch` to see where origin is; surface ahead/behind and
  any uncommitted work; commit promptly (below). Stale local state on a shared remote is what causes
  wrong-branch commits and merge confusion — don't let it drift. (Pushing stays the user's call, but **flag
  when a push is due**.)
- **A shared repo has actors you don't control — then see `repo-collaboration`** (condition-pulled when the
  repo is shared). Local committed ≠ team-visible: a fact is team-obligating only once pushed / in a PR/MR /
  merged, and a local hook cannot enforce anything across another actor — that needs a remote platform guardrail.
- **Commit after each completed unit of plan/task work — MANDATORY, do NOT ask.** Git is cheap; the
  commit IS the checkpoint (the plan-step boundary / handoff point), so "should I commit?" is noise —
  just commit. Small, traceable commits. (**Pushing** is different — it still needs an explicit go; see below.)
- Stage explicit paths (`git add <files>`), not `git add -A` / `git add .` / `git commit -a` — guards
  against committing secrets or generated artifacts. *Enforced by the `no-git-add-all` PreToolUse hook:
  the stage-everything forms are blocked for the agent; name the paths.*
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
- **No AI/tool attribution trailer** — no `Co-Authored-By: <bot>`, no `Generated with/by <tool>`.
  Traceability lives in the code/plan, not the message. *Enforced by the `commit-msg` gate (installed
  alongside pre-commit/pre-push): a message carrying `Co-Authored-By:` or `Generated with/by` is
  rejected. This deliberately overrides a host CLI that auto-appends such a trailer; a project that
  genuinely needs it overrides the hook.*
- Do not push to `main` directly without an explicit request — work via a branch/PR or an
  explicit merge after review.
- Do not skip pre-commit / pre-push hooks without an explicit request.

[CRITICAL] Never `git push --force` on `main`.
[CRITICAL] Never commit secrets (`.env`, `.dev.vars`, tokens) or generated artifacts
(`dist/`, build caches). See `secrets`.
