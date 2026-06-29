---
name: seo-analytics
description: Search Console analytics loop. Apply when measuring/improving published content's search performance.
---

# seo-analytics

Not a domain — a loop over content + web: publish → measure → improve. Maximum result with
one GSC-MCP; reuse the rest.

Tool: GSC-MCP (Search Console) — queries, impressions/clicks/positions, indexing. Auth:
OAuth or service account (like CF). Fallback: Playwright if no connector.

Use (all are GSC-MCP capabilities, ~0 extra cost):

- **Quick Wins** — pages ranking 4–15 → priority to improve;
- **Submit URL for indexing** — ping a new page;
- **Cannibalization detection** — two pages competing for one query.

Deliberately not now: Keyword Planner, GA4 behavior analytics (high ownership cost;
activate on real need).
