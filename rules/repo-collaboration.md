---
name: repo-collaboration
description: Multi-actor shared-repo mode — several humans/agents writing one repo. Pulled by the init survey ("shared repo?") or later; NOT a subject domain. Apply when >1 actor shares the repo.
---

# repo-collaboration

The baseline is **mono**: every invariant is held by *one disciplined operator reads the rule and acts
right*. The moment a repo is **shared by >1 actor** (another human + their agent sessions), that holder
fails — under speed discipline loses, and nothing surfaces work you did not start. This rule is **pulled
by a condition** (the init survey's "shared repo?" question, or later via the deploy ladder), like
`delegation` / `astro` — it is **not** a subject domain. Think of it as `delegation`'s discipline with the
enforcer moved from a lead to the **git platform** — across independent humans no lead exists to enforce.

Keep it thin: the rule POINTS to mechanisms, it inlines none.

## Principles
1. **One authoritative write path at a time.** A shared boundary — a contract, `src/shared/**`, a schema —
   has exactly one owning write path; everyone else **references**, never writes across it. References may
   be many; *mutation* needs ownership, review, or an agreed protocol. (This is *one home per fact* at a
   zone boundary — canon law 4.) A guard that reads another zone's source must **degrade** (a fallback),
   never hard-fail into "edit their file or merge a red main".
2. **A cross-actor invariant is held REMOTELY — not by discipline, not by a local hook.** The holder for a
   must-hold shared-path invariant is a **platform guardrail**: the platform's protected-branch +
   required-review feature + `CODEOWNERS` (GitHub / GitLab / Gitea / … — names and paths differ, the
   mechanism is the same; verify yours). Not prose, not a local git/agent hook. *Remote/shared enforcement belongs at the
   platform / source-of-truth layer; a local hook only protects the current checkout and the current
   agent* — advisory across actors. (Canon law 2: a rule asks, a hook guarantees — here only a REMOTE
   guardrail guarantees.)
3. **Visibility ladder — a fact is team-obligating only as it climbs.** `local → pushed branch → open PR →
   merged main → deployed`. A decision in a local branch does not exist for the team; "merged" is not
   "deployed". Put work on the rung the team can act from — recorded-locally ≠ available-to-others.
4. **A shared mutable doc needs one mutable region per owner.** An append-to-end shared journal with no
   section owner conflicts on every parallel session. Give each side its own file, or own sections, or make
   it append-only + owned. (P4 is principle 1 applied to docs — ties `project-docs`.)
5. **Inbound work discovery is first-class.** The mono model sees only work it started or was asked for; a
   peer's PRs, review requests, and merged-but-undeployed work are **invisible** unless you go look. **At
   session start in a shared repo, and before editing shared facts, check inbound work from the repo's
   source of truth when available:** open PRs / MRs, review requests, assigned issues, active branches
   touching the same area. Review is **mutual** — if you request acceptance on your PRs you owe the same on theirs.
   (Model judgment held by a *trigger* — enumerate so you never skip for lack of visibility; stays
   rule-described, promoted to a hook only after repeated misses.)

## Two failure modes to guard
- **Stale base / divergence before write.** Everything done "right" against an old `main` can be a clean
  but socially-wrong change — another actor already moved the contract / path / plan. `fetch before git`
  is not enough: **re-read the affected shared facts (the contract doc, the owner's open PRs) immediately
  before editing them and before opening the PR**; on a real conflict STOP into arbitration, don't silently
  win.
- **Review starvation → deadlock.** Blocking self-merge (principle 2) without a release valve trades a
  break for a stall (a contract PR left sitting for days). Pair every self-merge block with an
  **escalation valve**: after an agreed wait, ping the owner / split the change / arbitrate.

[CRITICAL] Never self-merge a change to a shared boundary (a contract, `src/shared/**`, a schema) past a
pending or absent owner review — this is exactly what the remote guardrail must prevent; if review stalls,
escalate, do not merge to beat the wait.

## Mechanisms (the chain)
- **`CODEOWNERS` template + branch protection** — the remote guardrail for principle 2. The template is
  **inert** until installed at a platform-recognized path *and* the platform's protected-branch rule
  requires review from the named owners (see `templates/CODEOWNERS` — platform-agnostic; GitHub / GitLab /
  Gitea differ in path and setting, Bitbucket uses its own default-reviewers). Standing this up on the
  platform is a per-repo, owner-level action — the rule names it; it is not automated here.
- **`boundary-guard` (reused, ADVISORY here)** — seed its `patterns.conf` with this repo's shared paths so a
  local Write/Edit to one *pauses for a reminder* ("shared path — is inbound checked, does branch protection
  hold?"). A local nudge, **not** the cross-actor guarantee — that is branch protection. Same hook as
  `delegation`; one `patterns.conf`, seeded as the union.
- **Ownership structure for shared docs** — principle 4, applied through `project-docs` (section owners /
  per-side files).

The concrete zones, owners, and the escalation wait live in the PROJECT (`AGENTS.md` / `CODEOWNERS`) — this
rule is the pattern, the roster is per-project.
