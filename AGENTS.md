# Canon `~/.agents/AGENTS.md` — global, not a project file

## Purpose

**The rule is the entry point.** The user picks a rule — and **bootstrap** deploys its
chain (skill, agent, MCP) by the link map in `~/.agents`. The rule itself deploys
nothing: it declares its dependencies, and bootstrap deploys them. The user does not
assemble a set by hand — one choice brings a consistent chain. This is what delivers
uniformity across all described scenarios.

**Provided** the library (`~/.agents/{rules, skills, agents, templates}`) is filled
with base rules and their tools, and their links are described in the map `map.yaml`.

## Directive: where typical behavior lives

Typical behavior (secrets, errors, planning, linters, md→pdf pipelines, etc.) is **not
stored in the canon as text.** It is laid out across the library layers and linked by
the map:

- `rules/` — the rule: what and in what order (the entry point);
- `skills/` — execution of the rule (the procedure);
- `agents/` — the executor (subagent);
- `templates/` — file templates (styles, configs);
- `hooks/` — deterministic guardrails (git hooks + agent PreToolUse/PostToolUse); a rule asks, a hook guarantees;
- `map.yaml` — the **link map** `rule ⇒ skills / agents / MCP / templates / hooks` (a logical graph, names only);
- `mcp-configs.yaml` — MCP configurations by name (`command`, `args`, `type`); from these bootstrap generates the runtime formats.

**Bootstrap pulls a rule's chain by the map** — the rule itself deploys nothing, it only
declares its dependencies. Deployment happens in two cases:

1. at the **survey** during initialization — for the chosen rule, bootstrap deploys its chain;
2. during **work** — by an explicit user request ("update the rules", "attach rule X")
   or when the agent notices something new in `~/.agents/rules/` (a one-shot
   `find ~/.agents/rules/ -type f`, not a constant diff): it reads the map in
   `~/.agents` and pulls the chain (`cp`) into the project.

What is carried over is recorded in the local `AGENTS.md` via the pointer. The user
creates their own skills the normal way (via `/` in the agent); they are not part of
the map, but are recorded in `./.agents/REGISTRY.md` by the self-configuration rule.

### Language policy

- **Canon and library artifacts** (`rules/`, `skills/`, `agents/`, `templates/`, `hooks/`,
  the comments in `map.yaml` / `mcp-configs.yaml`) **and the project `AGENTS.md`** (pointer /
  behavioral / self-config) — **English**. They are agent-oriented, cross-agent (Claude /
  Codex / opencode), and load into context every session; English is the consistent,
  token-cheap, instruction-reliable choice. Language follows **who loads the file, not whose
  project it is**: even in a non-English project the agent-loaded structure stays English.
- **User-facing and output documents** — working notes (plans, findings) and anything the
  agent **generates for the user** (reports, content, summaries) — **free language**: the
  user's language or the target market's locale. The agent must NOT force English onto an
  output; output language follows the audience (the `content` locale-by-market principle).
- Code, commands, paths, tool names — always as-is, regardless of the surrounding language.

## Bootstrap, deploy & refresh (procedure → `bootstrap.md`)

The procedures live in `~/.agents/bootstrap.md` — read and follow the relevant part **on trigger**;
they are NOT loaded every session. The canon carries only the triggers below.

- **[CRITICAL] Uninitialized folder → bootstrap BEFORE any work.** A folder is uninitialized if
  neither it nor anything above it in the tree (up to the root) has `./AGENTS.md` or `.git` — check
  upward exactly, so a subfolder of an initialized project is not mistaken for a new one. If
  uninitialized, read `bootstrap.md` and complete ALL its steps (the step-6 report is the completion
  signal) **before** you research, code, or answer — even when the first message is already a task.
  Otherwise, ignore bootstrap and work normally.
- **Need a new domain / rule / MCP** not yet in the project → `bootstrap.md` (deploy / self-config
  ladder): pull the rule + its chain from the library by the map, append to the local `map.yaml`,
  record the WHY in `REGISTRY.md`.
- **Library moved since the project's lock** (a rule / skill / agent / hook changed upstream, or an
  explicit "refresh") → `bootstrap.md` (refresh): 3-way merge on the lock commit, the wiring check,
  and the `AGENTS.md` self-reconcile — so the project stays current without any central roll-out.

## The library `~/.agents/`

```
~/.agents/
├── AGENTS.md         # this canon (directive + pointer; loaded every session)
├── bootstrap.md      # init / deploy / refresh procedure (read on trigger, not every session)
├── map.yaml          # link map: rule ⇒ skills / agents / MCP / templates
├── mcp-configs.yaml  # MCP configurations by name (command, args, type)
├── rules/            # reusable rules (md→pdf, linters, pipelines …)
├── skills/           # skills, loaded on demand; cross-agent
├── agents/           # agent/subagent definitions for reuse
├── templates/        # file and config templates
├── hooks/            # deterministic guardrails (git hooks + agent hooks)
└── plans/            # plan stubs (may be empty)
```

**Delivery principle:** the canon — by reference (a single source, on every session). The
library folders are copied into the project always and in full (an empty skeleton), then
filled per the survey — by value (a copy, not a symlink), and from there they live and
are edited in the project. Launching the survey is a soft instruction: it runs on the
first message, usually fires for all agents, but is not a hard trigger.
