---
name: project-docs
description: Project documentation and plans — must-have, kept current. Apply in any project when maintaining docs, plans, or decisions.
---

# project-docs

Documentation is **must-have**, not optional. The agent maintains it and keeps it current
alongside the code.

## Layout
Everything here is **Markdown (`.md`) by default** — greppable, diffable, plain-text source.

[CRITICAL] Plans, docs, decisions, and intermediate work-artifacts live **ONLY in the project** —
`./.agents/plans/{active,done}`, `./docs/`, and the project tree. **NEVER write them to `~/.claude/`,
`~/.codex/`, `~/.config/opencode/`, or any home/global agent folder** — those hold the agent's own
machine state, not the project's work (they don't travel with the repo and pollute other projects).
Scratch/temp → the session scratchpad or a gitignored project dir, never home.

- `docs/` — source of truth: architecture, contracts, key flows. Code follows docs.
- `./.agents/plans/active/` — plans in progress; `./.agents/plans/done/` — completed (move a
  plan on completion). Each active plan opens with a **handoff** note: what's done / what did
  NOT work / the single next step — so the next session orients without re-deriving.
- a backlog index — the single list of open work (name varies by project: `ROADMAP.md`,
  `TODO`, `docs/TODO.md`): short items + links to the detailed plans in `plans/active/`.
  Holds only open/unfinished work.
- decisions — an ADR log under `docs/`: a one-line manifest entry + the full body in an
  archive, capturing the decision **and dead-ends** (what was tried and rejected, and why);
  grep the archive before working in a zone.

## Discipline
- Contract-first: update the relevant doc (schema / contract / behavior) **before** the code change, then code.
- Keep docs consistent with the code; mark assumptions explicitly.
- A plan lives in `plans/active/` while in progress and moves to `plans/done/` when complete.
- A product-affecting plan gets a short item + link in the backlog index (no full duplication);
  on completion, move the plan to `plans/done/` and drop its backlog item — do not accumulate done.
- A decision records **why** (context, decision, alternatives, reason), not only what.

[CRITICAL] Do not ship a schema / contract / behavior change without updating its doc first.
