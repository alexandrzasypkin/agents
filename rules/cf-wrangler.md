---
name: cf-wrangler
description: Cloudflare via Wrangler + MCP. Apply when the project uses Cloudflare (Workers/Pages/D1/KV/R2).
---

# cf-wrangler

Cloudflare spans domains (TS → coding/web, Workers deploy → devops, D1 → db). One rule, one chain.

Two paths — split by purpose:

- management / queries (D1, KV) → Cloudflare MCP;
- deploy, local dev, migrations → `wrangler` CLI.

Access:

- OAuth (`wrangler login`) — beware a different account may be logged in on the machine.
- Scoped API token (`export CLOUDFLARE_API_TOKEN=…`) — main path for prod when OAuth points elsewhere.
- Always `wrangler whoami` → verify `account_id` before a prod operation.

Chain: `wrangler` CLI + Cloudflare MCP (D1/KV/R2/Workers) + TS checks (`tsc`, `eslint`).
Stack: TS, D1. Token handling → see `secrets`.
