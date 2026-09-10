---
name: proof-loop
description: Verify work independently, do not self-certify. Apply when claiming a task is done or correct.
---

# proof-loop

Do not confirm your own work by assertion. A task is "done" only after an independent
check passes:

- run the test / linter / type-check / validator — let the tool render the verdict;
- prefer a check that did not see your reasoning (a test, a fresh session, a reviewer)
  over "I wrote it and it looks right".
- **A check built on your own assumption is a mirror, not an independent verification.** When you
  hand-declare a foreign contract — a type written from memory, a mocked SDK, a homemade fake of an
  external service — the tests confirm the code matches *your hypothesis*, not that the hypothesis
  matches reality; the green proves the shared assumption, not the work. The independent source is the
  **docs / the real API / official types** — verify the contract there. Worse when the far side
  **silently accepts** an unknown field/arg (no error on a wrong name): the miss is invisible, so assert
  against the observable **effect** (the header arrived, the record changed), not that the call returned.
  (Incident: task-center 2026-09-10 — code sent `reply_to`, the Cloudflare Email binding wanted `replyTo`
  and dropped the unknown field silently; the hand-declared type carried the same invented name, so 344
  green tests proved only the shared mistake — caught by the first real send.)

[CRITICAL] "It works" without an independent verification is not a completion. Give
yourself a way to *prove* the work, not arguments that it works.
