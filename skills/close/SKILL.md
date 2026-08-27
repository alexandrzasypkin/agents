---
name: close
description: Close out a work session so the next one starts cold and moves immediately — verify the state is really what it looks like, record what only this session knows (decisions, dead premises, unverified claims) where the project keeps its knowledge, fix documentation that no longer matches the code, and tidy up. Apply when the user ends a session, before a long break, or when asked to hand off.
---

# close — end a session so the next one starts at speed

A fresh session reads the repo, `git log`, `docs/` and the active plan by itself. It **cannot** recover
what happened in your head: why a decision went one way, which backlog item rests on a dead premise,
what you measured at what cost, and — most valuable — what you could NOT verify.

So this is not a ritual of writing "done": make the visible state true, then write down only what the
repo cannot say on its own. Work the steps in order; report in five to ten lines.

**Most steps just apply a rule at the session boundary — follow that rule, do not restate it. The two
close-specific steps (dead premises, the not-verified list) are spelled out.**

## 0. Find the anchors, don't assume them (`project-docs`)
Read where THIS project keeps things: the pointer in `./AGENTS.md`; the backlog (`docs/TODO*.md` /
`ROADMAP.md` / the active plan); the knowledge homes (`docs/`, `docs/decisions/`,
`./.agents/plans/{active,done}`, `./.agents/REGISTRY.md`, `./.agents/runbooks/`); the project's own
deploy/verify commands (read its scripts — never carry a habit over from another project).

## 1. Make the state real — verify, don't assert (`proof-loop`)
Never write "shipped" from memory; confirm by an independent check and report the numbers you saw:
`git status` clean? `git log origin/<branch>..HEAD` pushed? the gate green with actual counts? the
**deployed artifact** verified — fetch the page / grep the string / read the header, not the command's
exit code? background jobs you started still running? A step you skipped is a line in the report, not a
silence.

## 2. The task index must tell the truth
For each item touched, record briefly: **what changed**, with the measurement that justifies it
(before → after, in the unit that matters — a number nobody has to re-derive is the most valuable line);
**why**, incl. the alternative rejected and its cost; **what surprised you** (a defect uncovered, a
guard that turned out vacuous, an assumption that was wrong).

Then check the items you did NOT touch for **dead premises**. If this session proved a backlog item
rests on something untrue — the numbers changed, the work is already done, the feature was never
requested — strike it **with its provenance** ("this line came from X on Y; measured today, it is Z").
Never leave it "still open", never delete it silently (an unexplained deletion comes back as a
rediscovery). **A description of behaviour that does not exist is not a task** — strike the claim, don't
file the gap as work (that turns a typo into a commitment); ask the owner when unsure which it is.

## 3. Record knowledge in its home (`project-docs`)
Write it down only when a fresh session would otherwise repeat a mistake or redo an investigation, and
put it where `project-docs` says: a decision in `docs/decisions/`, an attach/change rationale in
`REGISTRY.md`, a standing procedure in `runbooks/`, a handoff at the top of the active plan — **never in
`~/.claude/` or any home folder** (native memory does not travel with the repo). Not worth recording:
what the code or `git log` already says, what matters only inside this conversation, restatements of the
index. Prefer editing an existing entry over a near-duplicate; delete what this session proved wrong.

## 4. Documentation drift (`project-docs`, contract-first)
If behaviour changed, the docs describing it are suspects. Check the claims you touched — not the whole
file — and verify each before repeating it (grep the number, open the file, run the command). The
recurring failure is a sentence that was true once and is quoted as fact for months.

## 5. Say plainly what is NOT verified
The single most useful paragraph for the next session. For each thing shipped: **verified how** — live
measurement, browser check, test, or reasoning only; **what could not be verified and why** (a tooling
limit, needs a real user session, a viewport you cannot produce); **what waits on someone else** — the
owner's eyes, another repo, an upstream endpoint — with the issue number. Never let "deployed" stand in
for "verified"; if the only evidence is a zero exit code, say exactly that.

## 6. Tidy (`workspace-hygiene`)
Stop the dev servers / background jobs you started; remove scratch files, `.bak` copies and probes
(session scratchpad if they may be useful, never the repo); confirm nothing unintended is staged or
committed.

## Report (five to ten lines)
- **State**: gate result with counts, what is deployed where, push status.
- **Shipped**: one line per item, each with its measurement.
- **Learned**: the surprises worth carrying, and where they are now written.
- **Not verified**: the honest list, and who has to look.
- **Next**: what is genuinely ready to pick up, and what it depends on.

No summary of the conversation, no restatement of what the index already holds.
