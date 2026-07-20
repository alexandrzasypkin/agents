# runbooks — standing operational procedures the agent executes verbatim

A runbook is the **concrete, repeatable procedure** for one operation on *this* project — deploy,
restore, secret-rotation, DB-migration. One file per operation (`deploy.md`, `restore.md`, …). It is
the project's **facts**, resolved once and then followed without re-derivation, so the same operation
runs the same way every session instead of being reinvented each time.

## Why runbooks live here, and not elsewhere

| Home | What it is | Why a runbook is not there |
|---|---|---|
| `docs/`, `wiki/`, `guide/` | **user / product** documentation (`user-docs`) | a runbook is agent-operational, never shown to product users |
| `docs/` (dev source of truth) | architecture / contracts / ADR we author (`project-docs`) | that is design *why*; a runbook is an executable *how* |
| `.agents/plans/{active,done}` | **ephemeral** work, archived to `done/` | a runbook is **standing** — it never completes |
| `.agents/REGISTRY.md` | log of *why* the environment changed | not a re-executable procedure |
| `.agents/rules`, `.agents/skills` | library **method**, refreshed from `~/.agents` | a runbook is project **facts**; the library must never overwrite it |

So a runbook sits in the **agent layer** (`.agents/`) — committed, travels with the repo — but in its
own `runbooks/` folder, distinct from every genre above.

## Method vs. instance — the coupling

The skill chain is the **method** (how to deploy *in general*): `deploy-verify` → `deploy-models` →
`cf-secrets`. The runbook is the **instance** (how *this* project deploys). The method **references**
the runbook (`deploy-verify` step 0: "read `.agents/runbooks/deploy.md`, follow it verbatim"); the
runbook holds nothing generic. Keep them apart: the shared skill stays byte-identical across all
projects (uniformity), the volatile per-project IDs live only here.

## How management works

- **Write once.** On the first run of an operation, resolve the path from the skill chain, then pin it
  here. Absent runbook on a project that clearly ships = writing it **is** the first step, not extra.
- **Follow verbatim.** Every run after reads the runbook and executes it — no improvised alternative
  path. This is the whole point: it removes the "different every time" failure.
- **Update in lockstep.** Infra actually changed (new binding, new route, new secret)? Update the
  runbook in the **same commit** as the change — the runbook and reality never drift.
- **Committed, refresh-safe.** It travels with the repo (project memory must travel). A library
  refresh from `~/.agents` touches `rules/`/`skills/` — it **never** rewrites `runbooks/`, because
  these are project-authored facts, not library method. No merge-clobber risk.
- **Secret NAMES only.** A runbook names the secrets an operation needs; values stay in the secret
  file and are sourced through `cf-secrets` / a pipe — never written into the runbook (`secrets`).

## What a deploy runbook pins (the *what*, exactly)

Route (CI workflow + branch, or the fallback `wrangler deploy` command) · target names (worker / D1 /
queue / bucket / unit) · secret **names** · migration-vs-code order · the **verify** URL + expected
response · the **rollback** command. Markdown, checklist-style — a human or agent runs it top to bottom.
