---
name: code-search
description: Prefer a structural code index over grep/full-scan. Apply when searching a codebase for symbols, callers, or impact.
---

# code-search

Agents grep by habit and full-scan the tree (hundreds of K tokens, dozens of tool calls).
Prefer a **structural code index** when one is available.

- Index present (e.g. a CodeGraph / Gortex MCP) → use structural search (who-calls,
  what-breaks, symbol lookup) instead of grep / full-scan.
- Repo large enough that grep-scan is costly → set up an index per project. It is a
  **regenerable cache** (`.codegraph/` or equivalent) — gitignored, never committed.
- The index is a local SQLite database — keep it on a **local filesystem**; avoid network
  or cross-OS mounts (they cause SQLite lock errors). The agent places it correctly for its
  own environment (do not hardcode OS paths).
- No index and a small repo → `rg`/grep is fine. Do not add an index without measured pain.

Tool: CodeGraph (light, local) by default; Gortex for multi-repo. Project-level (self-config),
recorded in `./.agents/REGISTRY.md`.
