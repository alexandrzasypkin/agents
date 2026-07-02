---
name: delegation
description: Multi-agent orchestration for LARGE projects — a lead delegates to path-scoped subagents. Apply only when a single agent can't hold the project and it splits into clear owned modules.
---

# delegation

On a **large** project a single agent thrashes — it loses cross-module context, makes stray edits,
and pays for repeated full scans. Split the work: a **lead** orchestrates **path-scoped subagents**.
Do NOT use this on small or medium projects — one agent is simpler and cheaper. Activate on
**measured pain**, not preemptively.

## When is a project "large" (activate) — by BOTH signals, not by line count
1. **Clear ownership boundaries** — the code splits into **≥3 independent modules / services** with
   distinct concerns (e.g. api / webhook / schema / client), each editable in isolation.
2. **Measured single-agent pain** — one agent overflows its context, confuses modules, or keeps
   full-scanning because it cannot hold the whole tree.

Both must hold. Lines of code are only a rough hint (~50K+ LOC, e.g. 301 = 4 workers / 150K LOC) —
LOC alone does **not** make a project large, and a big-but-single-concern repo stays single-agent.

## The pattern
- **Lead** owns the plan, sequencing, and arbitration — not the code.
- **Scoped subagent** = owns ONE module / path (**write-scoped**), reads the whole repo for context,
  and **returns a cross-module spec to the lead** instead of editing outside its zone.
- **Read-only roles** (`reviewer`, `e2e`, `docs`) edit nothing — they report.
- **Order by dependency** — producers before consumers (schema / migrations → the code that uses them).
- **Parallelism** — independent modules run concurrently; dependent ones serialize.
- **Arbitration STOP** — on a cross-module conflict or ambiguity, the subagent stops and returns to
  the lead rather than guessing or reaching into another zone.
- **Change-protected files** (the project's rules / canon) are not edited by a scoped agent without
  the lead's explicit go.

## Native subagents — the mechanism (NOT pointer/chain)
Spawning, isolation, and parallelism are a **native** capability — they need the runtime's own
subagent mechanism (Claude Code `.claude/agents/`, spawnable by `subagent_type`; codex's own
equivalent). A pointer/chain role file in `./.agents/agents/` is **read** by the main agent: it
carries the role's guidance but does **not** spawn an isolated parallel context. So a delegating
project keeps its **spawnable roster as native subagents** (e.g. `.claude/agents/*.md`) — these stay
native, not moved to `.agents/`. Portable `.agents/agents/` role-files remain the default for the
non-spawned, cross-agent case (a single agent reads a role and follows it).

## Project-defined, not here
The concrete **roster** (which agents), the **ownership map** (which path each owns), and the
**phase order** live in the PROJECT — following its architecture — in the agent's **native** subagent
location (`.claude/agents/` for Claude). This rule is the pattern; the roster is per-project.
