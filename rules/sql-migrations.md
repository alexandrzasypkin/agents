---
name: sql-migrations
description: Database schema migration discipline. Apply when changing a database schema.
---

# sql-migrations

- All schema changes go in a migrations directory (`schema/migrations/` or the project's),
  as numbered files (`NNNN_<name>.sql`), one logical change per file.
- [CRITICAL] A committed migration is immutable — never edit an existing migration file. A
  fix is a NEW migration.
- Prefer additive changes (new columns/tables) over modifying or dropping. A breaking change
  needs an ADR (see `project-docs` decisions).
- Apply explicitly (a manual or controlled step), then record it in a migrations ledger
  (name, applied_at). No silent auto-apply on push.
- DB-agnostic: D1 (`wrangler d1 execute … --file=…`), postgres, mysql, sqlite — same
  discipline; the concrete client is project-specific (see `db` / `cf-wrangler`).
