---
name: no-hardcode
description: Values with an authoritative source are referenced, not frozen into code. Apply when writing code that carries business data, rates / thresholds, enumerable domain cases, or user-facing text.
---

# no-hardcode

A value that has a source — an API, a table, a config, a locale resource — is **read from that source**,
never copied into code as a literal. A hardcoded snapshot looks correct until the source moves: the
failure is silent (failure looks like success). This is canon law 4 (one home per fact) applied to code —
the source is the home, the code references it.

**The tell:** adding or changing a case should be a **data INSERT or a config change, not a code edit +
redeploy**. If a new rate / scheme / threshold / event needs a constant edited and shipped, the value was
in the wrong place — it belongs in data.

Scope is narrow — values with a source or that change by decision, NOT ordinary code constants
(`MAX_RETRIES`, `PI`, a loop bound are fine):

- **Decision / domain data** — rates, schemes, thresholds, enumerable domain cases, event names → a table
  row / config, so a new case is a row (ties `sql-migrations`: an additive row, never an edit to committed data).
- **Dynamic data** — anything an API / service owns → fetch it; never inline a table of it.
- **User-facing text** — never a literal in code, never one baked-in language → the locale / content layer
  (see `i18n`, which covers UI and backend-generated text: emails, notifications, bot / API replies).
