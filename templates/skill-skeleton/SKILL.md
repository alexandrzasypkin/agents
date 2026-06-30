---
name: <skill-name>
description: <what it does + WHEN to apply — this is the trigger, e.g. "Apply when ...">. Keep it specific; the agent loads the skill by matching this.
---

# <skill-name>

<One line: what this skill is for. Portable subset only: name + description frontmatter +
markdown body. No agent-specific fields (paths/hooks/model) in a baseline skill.>

## Quick start
<The single most common invocation / command.>

## Workflow
<Numbered steps of the procedure. Imperative, minimal — no prose padding.>

## Reference
<Pointers to `references/` and `scripts/` — reference them by explicit relative path in the
body (opencode does not auto-bundle). The agent reads only what a step needs.>

## Quality rules
<Constraints. `[CRITICAL]` for hard ones (security/correctness). Source of truth, no guessing.>

## Notes
<Tooling, fallbacks, platform. Keep the body < 500 lines; push detail into `references/`.>
