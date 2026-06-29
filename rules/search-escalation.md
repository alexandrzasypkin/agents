---
name: search-escalation
description: Source-retrieval ladder for research. Apply when searching the web for information.
---

# search-escalation

Search is a ladder, not a flat attempt. Escalate — do not stop at level 1:

1. **websearch** — open results, first pass.
2. **fetch the page** — when websearch returned only a snippet, pull the full URL.
3. **full browser** (Playwright) — JS render, pagination, soft-paywall, sites closed to fetch.

[CRITICAL] "Not found" is allowed only after the ladder is exhausted, not at level 1.
Report which level produced the result (fallback-with-disclosure).
