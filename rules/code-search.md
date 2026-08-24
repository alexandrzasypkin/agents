---
name: code-search
description: Route by the QUESTION — strings→grep, symbols→LSP, architecture/impact→structural graph. Apply when searching a codebase, tracing callers/impact, or BEFORE writing new code.
---

# code-search

Agents grep by habit and full-scan the tree (hundreds of K tokens, dozens of tool calls) — and write
duplicates because a blind search found nothing. **The tier is picked by the QUESTION, not by repo size
and not by what's cheapest to reach for.** Three lanes, by what you are actually asking:

1. **A literal string** — a log line, a config key, an error message, a comment → **`rg`/grep**. Only
   this: grep is for TEXT you already know, at any repo size. **Never grep to find or trace CODE** — it
   answers by NAME, and a name is not a symbol (see below).
2. **A symbol, locally** — this file's types, a definition, references, who-calls, rename impact,
   post-edit diagnostics → the **LSP tool** (a language server via the project's config): zero-setup,
   exact, symbol-resolved.
   - **grep answers by NAME, LSP by SYMBOL — a name with two definitions gives a right count but a wrong
     conclusion.** grep for `recordTransaction` counts every textual hit; if two modules each define one
     (api + webhook), the 13 hits read as *one* interface with 13 entry points when they are two
     independent functions with disjoint callers. For who-calls / how-many / what-breaks, LSP resolves
     the actual symbol — grep structurally cannot.
   - **On Claude, this tier is native.** A code-intelligence plugin (`pyright-lsp`, `typescript-lsp`,
     `gopls-lsp`, … from the official marketplace) wires the language server to Claude's built-in LSP
     tool: automatic diagnostics after every edit + navigation (def / refs / hover / call-hierarchy).
     Needs the language-server **binary** on PATH (`pyright-langserver`, `typescript-language-server`,
     `gopls`, …). Per-agent, install-when-needed (codex/opencode bring their own LSP); log it in
     `./.agents/REGISTRY.md`.
   - **Validate before you finish:** on the files you changed, check LSP diagnostics (types / imports)
     and fix what the server flags — an independent check closes the task, not your assertion.
   - **"Exact" holds only once the server is WARM — warm the area before trusting a COUNT or a MISS.**
     The server indexes lazily: a first query into a cold area answers from what it has loaded and
     signals the incompleteness *in no way* — `workspaceSymbol` can return "1 symbol" where three exist,
     then all three when repeated after touching a neighbouring file. A **positive hit is trustworthy; a
     count or an absence is not.** Touch a file in the target area, or repeat the query, before
     concluding "only one" / "none" — decisive for the anti-duplication search below, where a false
     "none" reads as "no duplicates" and closes the search.
3. **The macro shape** — where does this live, the call-chain across files, what breaks if I change X,
   how far a concern is spread → a **structural graph** (CodeGraph light/local; Gortex for multi-repo).
   This is a **FIRST** move for architecture / impact, **not a last resort** — query the graph instead of
   reading dozens of files to learn who calls whom. When a graph MCP exists, use structural search
   (who-calls, what-breaks, symbol lookup) over grep. A **template-literal / bundled blob is opaque** to
   the indexer (it sees a string, not an AST) — grep the string there.
   - **Provision it where duplication actually hurts.** The graph beats grep only if it is present; grep
     wins by being always-there. In a code-heavy project with observed cross-cutting duplication, set up
     the graph tier (a codegraph MCP + the LSP binaries) so the right tool is one call away — per-project
     self-config, recorded in `./.agents/REGISTRY.md`. Regenerable cache (`.codegraph/` or equivalent):
     gitignored, never committed; keep the SQLite DB on a **local** filesystem (network / cross-OS mounts
     → lock errors).

## Search BEFORE you write (the anti-duplication use)
The first job of search is not impact analysis — it is finding the code you'd otherwise duplicate.
Before adding a function / helper / type / endpoint / util: search for the concern — **by symbol via
LSP, by shape via the graph, by a distinctive string via grep** — and **reuse or extend** what exists.
In a codebase with cross-cutting overlaps (shared helpers, near-identical flows across modules) — even a
SMALL one — this is exactly where duplicates creep in: the agent writes blind because it didn't look. A
duplicate caught before it's written costs one search; caught later, a refactor. And trust the warm rule
above — a cold "none" is not "no duplicate".
