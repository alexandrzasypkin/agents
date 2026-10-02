---
name: code-search
description: Route by the QUESTION — strings→grep, symbols→LSP, architecture/impact→structural graph. Apply when searching a codebase, tracing callers/impact, or BEFORE writing new code.
---

# code-search

Agents grep by habit and full-scan the tree (hundreds of K tokens, dozens of tool calls) — and write
duplicates because a blind search found nothing. **The tier is picked by the QUESTION, not by repo size
and not by what's cheapest to reach for.** Three lanes, by what you are actually asking:

1. **A literal string** — a log line, a config key, an error message, a comment → **`rg`/grep**. Only
   this: grep is for TEXT you already know, at any repo size. **Never grep to find or trace CODE *as the
   answer*** — it answers by NAME, and a name is not a symbol (see below); as a DETECTOR that corroborates
   an LSP who-calls / count / "unused" it is standard order, not an exception (tier 2).
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
   - **A missing server is a cue to INSTALL it, not to fall back to grep.** grep answers by NAME — the
     wrong answer for symbol/who-calls/impact work — whether or not the server is present, so downgrading
     to it defeats the tier, it does not substitute for it. The LSP layer is near-zero-setup (a binary +
     plugin): install it and proceed, don't skip the question you actually have.
   - **Validate before you finish:** on the files you changed, check LSP diagnostics (types / imports)
     and fix what the server flags — an independent check closes the task, not your assertion.
   - **Trust LSP by OPERATION — a reference answer can be silently incomplete even when the symbol is
     fully visible.** A POSITIVE existence result — definition, hover, type, "this symbol is here" — is
     trustworthy. **who-calls, the reference COUNT, and "used nowhere" are not:** `findReferences` can
     return the definition and 0 of N real callers with no signal that it is partial — a wrong answer that
     reads as a clean one, worse than a slow one. Warming cures only the COLD-index case (a first query
     into a cold area undercounts — `workspaceSymbol` returns "1" where three exist, then all three after
     you touch a neighbour / repeat). It is **not** a general fix: measured (a TypeScript / CF-Workers
     project, 2026-10-01) a fresh function the server plainly sees — `workspaceSymbol` finds it,
     `documentSymbol` returns its whole file — still gave **0 of 4** references, unchanged after full
     warming. The cause is not always
     knowable (multi-root scope, a server limitation, a stale index); the discipline does not depend on
     naming it: **do not trust a reference count or an absence on faith, warm or not.**
   - **So the three questions that gate a dedup / rename / delete — who-calls, reference COUNT, "unused
     anywhere" — are corroborated with a text search as the STANDARD order, not an exception.** **rg is
     the DETECTOR, LSP the RESOLVER** (this does not reopen "never grep to trace code"): rg widens the
     candidate set; a file it hits that LSP's references omitted is a **flag, not an answer** — a name
     collision (two defs, above) or a caller LSP dropped — resolve each *from that file* (go-to-def at the
     call site). The positive hit stays LSP's; it is the COUNT and the ABSENCE that rg corroborates.
     Decisive for the anti-duplication search below, where a false "none" reads as "no duplicates" and
     closes the search.
3. **The macro shape** — where does this live, the call-chain across files, what breaks if I change X,
   how far a concern is spread → a **structural graph** (CodeGraph light/local; Gortex for multi-repo).
   This is a **FIRST** move for architecture / impact, **not a last resort** — query the graph instead of
   reading dozens of files to learn who calls whom. When a graph MCP exists, use structural search
   (who-calls, what-breaks, symbol lookup) over grep. A **template-literal / bundled blob is opaque** to
   the indexer (it sees a string, not an AST) — grep the string there.
   - **The trigger is reuse DENSITY, not repo SIZE.** Stand the graph up on either of two independent,
     each-sufficient signals: **(a) reuse density** — high fan-in, shared helpers, near-identical flows
     across modules, code that connects more than it sprawls — which qualifies **regardless of repo
     size**; a small, densely-reused tree is the *highest*-duplication-risk case, not the lowest, because
     every new function likely overlaps an existing one, and the overlap is semantic (who-calls), invisible
     to grep-by-name. **(b) grep-scan cost** — a large tree where reading to learn who-calls-whom is itself
     expensive. A 2k-line tightly-woven repo qualifies on (a) even though it never hits (b). What does NOT
     qualify: a one-off who-calls that found no graph — that question is LSP's (tier 2, always on, no gate),
     not a fresh index's. **This tier is NOT install-on-absence** — unlike the cheap LSP layer, the graph is
     a heavier index (a build + a DB), so provision it on (a) or (b), not reflexively. When one holds: set
     up the graph tier (a codegraph MCP + the LSP binaries) so the right tool is one call away — per-project
     self-config, recorded in `./.agents/REGISTRY.md`. Regenerable cache
     (`.codegraph/` or equivalent): gitignored, never committed; keep the SQLite DB on a **local**
     filesystem (network / cross-OS mounts → lock errors).

## Search BEFORE you write (the anti-duplication use)
The first job of search is not impact analysis — it is finding the code you'd otherwise duplicate.
Before adding a function / helper / type / endpoint / util: search for the concern — **by symbol via
LSP, by shape via the graph, by a distinctive string via grep** — and **reuse or extend** what exists.
In a codebase with cross-cutting overlaps (shared helpers, near-identical flows across modules) — even a
SMALL one — this is exactly where duplicates creep in: the agent writes blind because it didn't look. A
duplicate caught before it's written costs one search; caught later, a refactor. And trust the warm rule
above — a cold "none" is not "no duplicate".
