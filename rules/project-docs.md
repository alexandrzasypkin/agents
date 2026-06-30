---
name: project-docs
description: Project documentation and plans — must-have, kept current. Apply in any project when maintaining docs, plans, or decisions.
---

# project-docs

Documentation is **must-have**, not optional. The agent maintains it and keeps it current
alongside the code.

## Layout
- `docs/` — source of truth: architecture, contracts, key flows. Code follows docs.
- `./.agents/plans/active/` — plans in progress; `./.agents/plans/done/` — completed (move a
  plan on completion). Each active plan opens with a **handoff** note: what's done / what did
  NOT work / the single next step — so the next session orients without re-deriving.
- decisions — an ADR log under `docs/`: a one-line manifest entry + the full body in an
  archive, capturing the decision **and dead-ends** (what was tried and rejected, and why);
  grep the archive before working in a zone.

## Discipline
- Contract-first: update the relevant doc (schema / contract / behavior) **before** the code change, then code.
- Keep docs consistent with the code; mark assumptions explicitly.
- A plan lives in `plans/active/` while in progress and moves to `plans/done/` when complete.
- A decision records **why** (context, decision, alternatives, reason), not only what.

[CRITICAL] Do not ship a schema / contract / behavior change without updating its doc first.
