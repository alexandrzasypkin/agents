---
name: skill-creator
description: Author or update a skill — the full cycle (understand, draft, validate, forward-test, iterate). Apply when creating a new skill or revising one.
---

# skill-creator

Composes what we already have: the `skill-skeleton` template (the shape), `rule-format`
(conventions: thin, frontmatter trigger, `[CRITICAL]` sparingly), `proof-loop` (verify). Adds
the process + the forward-test below. Keep the result thin — concise is the whole point; a
skill shares the context window with everything else.

## Process
1. **Understand with examples.** Get 2-3 concrete cases of how the skill is used and what would
   trigger it. Do not draft until the usage is clear.
2. **Plan resources.** Decide what is reusable: `scripts/` for deterministic/repeated code,
   `references/` for on-demand detail (keeps SKILL.md lean), `assets/` for output files. Only what's needed.
3. **Draft** from `skill-skeleton`: `name` (lowercase-hyphen = folder), `description` = WHAT + WHEN
   (the trigger; all "when to use" goes in the description, not the body), markdown body <500 lines.
4. **Check overlap.** Confirm the skill is not already covered by an existing rule/skill.
5. **Validate format** — the portable subset only: `name` + `description` + body; no agent-specific fields.
6. **Forward-test, then iterate** (below).

## Degrees of freedom
Match specificity to the task's fragility: high freedom (text guidance) when many approaches
work; low freedom (a specific script, few parameters) when the operation is fragile and a
fixed sequence must hold.

## Forward-test (proof-loop for a skill)
Validate that the skill *generalizes*, not that an agent reconstructed the answer from context:
- launch a subagent that does NOT know it is testing — give it a realistic task + the skill path
  (`Use <skill> at <path> to do <task>`), not "review this skill" or "pretend a user asks…";
- pass raw artifacts, never your intended answer / fix / conclusion;
- fresh thread per pass; clean up the subagent's artifacts between iterations.

If it only passes when the subagent sees leaked context, the skill is too weak — tighten it.
