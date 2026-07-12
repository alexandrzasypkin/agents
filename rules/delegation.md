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

## Spawn only what needs isolation (Skill / Hook / Subagent)
A subagent's job is to **isolate work** in its own context. Before spawning, check it isn't one of
these instead:
- a **technique / know-how** → a **skill** (loaded into context, no separate instance);
- a **deterministic step** (run tests, lint, a build) → a **tool call** (bash), not an agent;
- an **enforced rule** (block on a failing check) → a **hook**.
Rule of thumb: **a skill teaches "how", a hook enforces "the rule", a subagent isolates "the work".**
Don't spawn for what a skill/tool/hook already does — spawning costs ~7× the tokens (see below).

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

## Orchestration & cost
- **Sequential** (pipeline) — each stage consumes the previous (spec → implement → test).
- **Parallel** — independent modules at once; **3–5 is the sweet spot** (more = coordination overhead).
- **Fan-out** — dozens of agents to cover a large space (audit every file), when work is embarrassingly parallel.
Sequential is cheaper than parallel; parallel cost grows ~linearly with agent count; a subagent-heavy
run is **~7× the tokens** of one session — another reason delegation is large-projects-only.

## Least-privilege roles (tools + model)
Each role declares a **least-privilege `tools` allowlist** in its frontmatter — never full access.
A refactor agent with unrestricted `Bash` can `git reset` and lose work; a **read-only** role
(`reviewer`, `e2e`, `docs`, `searcher`) gets `Read, Grep, Glob` (+ `Bash` only if it must run gates),
never `Edit`/`Write`. Pick a **`model`** by role too — a cheap one (haiku) for read-only search/review,
a strong one (opus/sonnet) for critical writers. When spawning from `.agents/agents/`, the lead honours
the role's declared `tools`/`model` (pass them to the Task/Agent call).

## The mechanism — spawn from `.agents/`, don't rely on a native registry
Spawning, isolation, and parallelism come from the **Task/Agent tool**, not from a native
`.claude/agents` registry. The lead **loads a role from `./.agents/agents/<name>.md`** and **spawns a
subagent** with that role as its brief — a real isolated, parallel context. (Claude Code's
`subagent_type` registry in `.claude/agents/` is only a shortcut that turns a role into a system
prompt; it is NOT required — loading the role from `.agents/` and spawning a general-purpose subagent
gives the same isolation and parallelism, from a single portable source.) So the roster lives in
`./.agents/agents/` like everything else; `.claude/` stays system-only (settings: hooks/permissions).

## Project-defined, not here
The concrete **roster** (which agents), the **ownership map** (which path each owns), and the
**phase order** live in the PROJECT (`./.agents/agents/` + `AGENTS.md`) — following its architecture.
This rule is the pattern; the roster is per-project.

## Enforce hard invariants with a hook
The `boundaries` ownership map is a **soft** rule the lead upholds. For the subset that is a hard,
**role-agnostic path invariant** (generated files not hand-edited, committed migrations immutable,
server-only dirs, `dist/`), back it with the **`boundary-guard`** hook (`patterns.conf`) — a PreToolUse
guard that pauses a matching write for approval. A rule asks, a hook guarantees. Per-role write-zones a
hook **cannot** see (it doesn't know which subagent is acting) — those stay the rule + lead arbitration.
