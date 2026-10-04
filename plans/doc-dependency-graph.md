---
name: doc-dependency-graph
type: plan
status: deferred
tags: [docmap, project-docs, frontmatter, graph]
---

# Doc dependency graph — typed frontmatter edges (DEFERRED)

**STATUS: DEFERRED — gated on a trigger. Do NOT build until it fires (law 5).** Recorded so the
sketched form is not lost. Discussed 2026-10-04; not landed in the canon.

## The question it answers
"I change doc-level contract B — which docs break?" — the document analogue of who-uses / what-breaks.

## Build trigger (the missing incident)
A **doc-level** contract (NOT a code symbol) changes, a consumer breaks, and the impact-set was missed
because it was computed by memory/hand. Code-symbol contracts are already covered by LSP / codegraph
(`code-search`) — this earns its place ONLY where the contract is a document, not a symbol.
Near-miss seen but not yet decisive: a shared payload type changed meaning, consumers broke, impact-set
guessed by hand (repo-collaboration, failure mode F1 "stale base"). When a clearly doc-level case lands —
build.

## Minimum form (capped)
- Two resolvable frontmatter fields on `docs/` contracts/specs only (not every note):
  `owner:` (authoritative writer — also feeds repo-collaboration P1/P4 + CODEOWNERS) and
  `consumer_of: [path, ...]` (this doc's outgoing dependency edges). Optional `contract-status:`
  (proposed|agreed|implemented|available) ONLY on docs that ARE a contract.
- **Graph is DERIVED, never stored.** Each author maintains only their own doc's outgoing edges (part of
  the existing contract-first "sweep every occurrence"). `docmap --rdeps <path>` computes the impact-set
  from everyone's `consumer_of` declarations. This is what distinguishes it from the hand-maintained
  "doc link-graph" that `project-docs` deliberately rejects (which lags and lies).
- **docmap validates** (the honesty mechanism): edge resolves (not dangling), target not
  archived/superseded, no `consumer_of` on a dead owner, legal `contract-status` transition.
- **Hard cap: ≤3 edge types.** More (`blocks`, `relates-to`, …) only from a fresh incident, or it
  re-grows the graph-bureaucracy we avoid.

## For / against (summary)
- FOR: cheap impact-set without a hand-kept map; honest-by-construction (derived + validated); reuses
  docmap + frontmatter (extension, not a new subsystem); `owner:` is one fact reused by CODEOWNERS.
- AGAINST: semantic drift docmap can't catch (edge true-by-path but stale-by-meaning); the relation now
  lives in two homes (body link + frontmatter edge) unless docmap cross-checks; scope-creep pressure;
  law 5 — no decisive doc-level incident yet; code contracts already served by LSP/graph.

## Where it lands when built (NOT a new rule)
Extend the `docmap` skill (resolve + validate edges, `--rdeps`) and add a few lines to `project-docs`
(the typed-edge fields + the derived-not-hand-kept caveat). No new rule; no new domain.
