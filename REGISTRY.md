# Журнал адаптаций

## 2026-08-06 — published to a public git remote + cross-OS installers

**Remote:** `alexandrzasypkin/agents` (GitHub, PUBLIC, read-only for consumers) via SSH `git@github-a3`
(`id_ed_opr`). Model: consumers clone/pull anonymously over HTTPS (no key); write is owner-only.
Trust anchor: commit SHA over HTTPS/TLS (**SHA-only** — no GPG signing, by decision). Snapshot tags
`snapshot-<date>` mark milestones. Added `.gitignore` (library had none); untracked a stray `.pyc`.

**Installers** (`runbooks/`): `install.sh` (POSIX) + `install.ps1` (native Windows). Both: clone-or-pull
(never clobber; `--ff-only`), symlink the canon **only for detected agents** (not all 3 need be present),
integrity report. Opt-in `--install-baseline-guard` / `-InstallBaselineGuard` (one-shot: `sh -s --`,
`$env:AGENTS_BASELINE_GUARD=1`) idempotently installs the global guard per present agent (codex TOML
append, claude JSON merge, opencode plugin copy). Default stays guide-only (security control = deliberate).

**⚠ OPEN — verify later:** `install.sh` guard-logic was tested live on Linux (JSON merge preserves
existing hooks/permissions ✓). **`install.ps1` is NOT verified on a real Windows box** (no `pwsh`/Windows
available as of 2026-08-06) — especially the claude `ConvertFrom/To-Json` merge path. Eyeball its output
on first Windows run. Windows hooks also need Git Bash (`bash` on PATH) or agent adaptation — `install.ps1`
warns when installing the guard without `bash` (hooks are POSIX; canon 229–232: the agent adapts on native Windows).

## 2026-08-06 — gap-closure against the agent-failure taxonomy

**Source:** Scale AI, *Model or Harness? An Interaction-Centric Taxonomy for Localizing Agent
Failures* — arXiv `2607.28802` (https://arxiv.org/html/2607.28802v1). 41 failure modes on
interaction edges, each with a **fault-side** (model vs harness). Reviewed our library against it.

**Operating principle adopted (the paper's payload):** the **model/harness fault-side axis**. The
library is pure harness → it can *guarantee* a fix only for harness-side modes; for model-side modes a
rule is a *nudge*, not a fix. Do not harness-engineer a model problem (the classic mislocated fix).

**Finding:** the memory-*write* family already mapped 1:1 onto existing discipline (commit-memory,
delete-wrong, don't-duplicate, REGISTRY-why, add-rule-only-after-incident). Real gaps were on
**reads** and **trust of ingested content**. Closed:

| # | Mode (fault-side) | Change | Commit |
|---|---|---|---|
| 1 | Indirect prompt injection (model, soft) | new base rule `untrusted-content` + `map.yaml` base/registry | `918d928` |
| 2 | Missed-read / memory-following (harness) | canon seed + `project-docs` name both read-side misses | `918d928` |
| 3 | State staleness (harness) | `project-docs` Discipline: drifted doc = first-class failure; `status: archived` filters it | `b575bde` |
| 4 | Context-rationale-erosion / compaction (harness) | canon seed: compaction is lossy → externalize before loss, distrust the summary on resume | `b575bde` |

**Also:** incident-layer in the canon seed now carries the **fault-side reflex** (ask model- vs
harness-side before writing an incident rule). Deliberately **not** adopted: per-incident tagging with
the full 41-mode vocabulary (over-machinery) and a standalone taxonomy doc (parallel source of truth —
the paper is the reference, linked here, not transcribed).

**Propagation to the 8 projects:** canon (`AGENTS.md`) is global via symlink — immediate; `untrusted-content`
lands as a new base rule; `project-docs.md` via the CHANGED-file trigger + 3-way merge. No central sweep.
