---
name: content-vault
description: Content & knowledge base for non-dev audiences — capture→process→publish/archive, plus a local semantic index when retrieval hurts. Apply on a content-heavy project (content domain).
---

# content-vault

The layer above `project-docs` for projects that produce or manage **content / knowledge for non-dev
audiences** (marketing, client, published material, a research vault). Everything is Markdown; the same
[CRITICAL] "in the project, never home" and standard-relative-links rules from `project-docs` apply.

## `content/` — deliverables for others
`content/` holds authored material for **non-dev audiences** (business / client / marketing / published),
separate from `docs/` (dev source of truth) and `context/` (consumed inputs). Flat by default; split by
audience (`content/marketing/`, `content/client/`, …) only when it earns its keep. Language: the
audience's / market's locale (see `user-docs`, `i18n`), not English-by-default.

## Lifecycle — capture → process → publish/archive
- **Capture** — raw draft in an inbox or `context/`, no frontmatter yet.
- **Process** — refine → add frontmatter (`type`/`status`/`tags`) → place in `content/` (or `docs/`).
- **Publish** — mark `status: published`; render/export per surface: PDF via `md2pdf`, image/video via
  `media`, site/search via `seo` / `seo-analytics`. The Markdown stays the source.
- **Archive** — superseded → `status: archived`, **out** of the agent's active context.

Producer chain for the source material: research (`search-escalation` — web / yt-dlp / whisper) → draft
(`writing-style`) → export (`md2pdf` / `media`) → publish (`seo` / `seo-analytics`). For a **how-to /
onboarding walkthrough of a live product UI**, capture the flow via `browser-use` (drive the real UI →
screenshot each step → narrate) rather than describing it from memory.

## Semantic retrieval (doc-RAG) — later, on measured need
When frontmatter-filtering over `docs/` + `context/` stops scaling, add a **local SQLite index**
(`sqlite-vec`): embeddings + vector search in a local `.db`. Same class as the `codegraph` code index —
**project-level, gitignored regenerable cache, local filesystem only** (SQLite locks break on network /
cross-OS mounts — see `code-search`), **OS-resolved** (the `sqlite-vec` extension binary per OS; SQLite
built with loadable-extensions). Don't build it without measured retrieval pain; the frontmatter filter
is the default. Record it in `REGISTRY.md` when attached.
