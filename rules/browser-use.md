---
name: browser-use
description: Playwright browser usage — console/result mode vs UI/user-in-the-loop. Apply when driving a real browser (auth, forms, UI verification), not headless scraping.
---

# browser-use

Two modes — pick by who must act. (Headless scraping for research is `search-escalation`.)

## Console mode — agent drives, the user sees only the result
The agent runs the work through the browser (e.g. `browser_evaluate` with inline JS: fetch
an authed endpoint, read the return value / console). The user sees the outcome, not the steps.

- Use for: authed reads, verification, an action under a session/fingerprint-bound auth.
- Authed/session work goes through the user's **already-logged-in browser**, NOT curl (an
  agent-shell curl fails fingerprint/cookie checks → 401). No secret or token is passed to the agent.

## UI mode — agent prepares, the user commits
A visible browser; the agent acts on the page like a user.

- The agent **fills form fields from prepared data** (the tedious part).
- [CRITICAL] **Passwords and secrets: the user types them.** The agent never enters or reads a password.
- The agent fills, then **waits** — the **user clicks submit / the final button**. The agent
  does not commit a consequential action itself (submit, pay, delete, deploy); it stages it
  and hands the click to the user.

## Before any action
- Confirm destructive operations (delete, bulk, deploy, pay) with the user; use dry-run where available.
- Log the result in the conversation (audit trail).
- Endpoint, auth, and account specifics are project-specific — see the project, not this rule.

## Three lanes — pick by goal
1. **Scripted tests** (`playwright test`, `.spec.ts` in `tests/e2e/`) — deterministic, versioned,
   network interception + built-in asserts/retry. Install-agnostic: native if present (no Docker),
   Docker only where a native install is blocked, or CI. **Default for regression / CI / critical paths.**
2. **Interactive MCP → QA** — the agent drives the real browser: exploratory checks, live debugging,
   interactive auth (captcha/2FA/Turnstile). No built-in asserts/retry; the accessibility tree may not
   match the visual state. (console vs UI mode above = who commits the consequential click.)
3. **Interactive MCP → content** — the same drive-the-UI mechanic, but the OUTPUT is instructional
   material: walk a real user flow, `browser_take_screenshot` each step, narrate → a how-to / onboarding
   walkthrough. Feeds `user-docs` (product users) or `content` (marketing/onboarding); screenshots are
   assets (by the guide / `content/attachments`).

Structured UI / E2E testing (read-only, UI-only, screenshot per step, pass/fail report) → the `e2e` agent.
(Local-first / interactive-only-when-needed is the general MCP principle — not restated per-tool here.)
