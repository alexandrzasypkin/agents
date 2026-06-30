# ~/.agents — agent environment library

A cross-agent environment for Claude, Codex, and opencode. One choice — the project's
domains — deploys a consistent set of rules, skills, subagents, and hooks into a project; the
agent then self-configures and adapts. `AGENTS.md` is the normative spec (the canon); this
README is the overview.

## Purpose

Stop hand-assembling per-project agent setups. Pick domains at init, and the library deploys
a known set (linters, formatters, git hooks, pipelines, subagents). Two projects that pick the
same domains get the same setup. Existing behavior is captured once and reused, not re-typed.

## Key design: pointer / chain, NOT native menus

Skills, subagents, and rules are NOT loaded through Claude's native systems (`.claude/skills`,
`/` slash-commands, the Task subagent registry). They live in `./.agents/` and are found two ways:

- the **pointer** in the project `AGENTS.md` ("rules/skills/agents → `./.agents/`");
- the **chain** in `map.yaml`: a rule names its skill / subagent / MCP, so a skill is pulled in
  *because its rule is active*, not because it sits in a native menu.

Why: this makes the system identical across Claude / Codex / opencode and independent of any
one agent's folder conventions (a project may have no `.claude/` at all). The trade is that the
agent *uses* a skill or role by reading its file, with no native `/command` or Task-spawned
isolated subagent. The only `.claude/` file we rely on is `settings.local.json` (Claude's
permissions + hooks runtime anchor).

## Structure

```
~/.agents/
├── AGENTS.md         # canon: the directive + BOOTSTRAP spec (loaded every session via symlink)
├── map.yaml          # the graph: base (always-on) + types (selectable domains) + rule → chain
├── mcp-configs.yaml  # MCP recipes by name (portable; env-specifics resolved at bootstrap)
├── rules/            # reusable rules (the entry points)
├── skills/           # procedures (incl. skill-creator, a library-resident meta-skill)
├── agents/           # subagent definitions (docs, reviewer, searcher, …)
├── templates/        # file templates (skill-skeleton, plan, pdf-style, gitignore)
├── hooks/            # deterministic guardrails (git + agent hooks)
└── plans/active|done # plan lifecycle stubs
```

`base` rules apply to every project; `types` are the domains the survey multi-selects. The
final rule set = `base ∪ selected domains`. Library artifacts are **English**; a project's
user-facing and output docs use the audience's language.

## Setup

The canon is attached to each agent by symlink, so it loads every session (even in an empty
folder). After you have `~/.agents` — and whenever you install a new agent — link it:

```bash
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md    # Codex reads AGENTS.md
ln -sfn ~/.agents/AGENTS.md ~/.claude/CLAUDE.md   # Claude reads CLAUDE.md (no native AGENTS.md)
```

opencode reads `~/.agents` natively and gets the canon path from each project's `opencode.json`
(written at bootstrap) — no global symlink needed.

On native Windows the `ln` form works from Git Bash / WSL2. In cmd or PowerShell create the
links directly — needs Developer Mode on (or an elevated shell), the parent dirs must exist,
and the link/target order is the **reverse** of `ln`:

```cmd
mklink "%USERPROFILE%\.codex\AGENTS.md"  "%USERPROFILE%\.agents\AGENTS.md"
mklink "%USERPROFILE%\.claude\CLAUDE.md" "%USERPROFILE%\.agents\AGENTS.md"
```
```powershell
New-Item -ItemType SymbolicLink -Path "$HOME\.codex\AGENTS.md"  -Target "$HOME\.agents\AGENTS.md"
New-Item -ItemType SymbolicLink -Path "$HOME\.claude\CLAUDE.md" -Target "$HOME\.agents\AGENTS.md"
```

Optional but recommended: install the global `hooks/baseline-guard/` so writes to `~/.agents`
need your explicit approval (see its README). Per-project hooks and anchors are created by
bootstrap, not here.

## How a project is set up (bootstrap)

A fresh agent in an uninitialized folder reads the canon and runs BOOTSTRAP: survey the
domains → deploy `base ∪ domains` chains into `./.agents/` → write runtime anchors and
deep-merge per-agent hook/MCP configs → `git init` + install git hooks + `.gitignore`. From
then on the project is autonomous; it self-configures (pull / install / adapt) and logs *why*
in `./.agents/REGISTRY.md`.

## Guardrails

- **baseline-guard** (global): writing to `~/.agents` needs your explicit approval (native ask);
  reading/copying from it is free.
- **git-quality-gate**: mandatory pre-commit/pre-push lint/type/test + an unconditional secret scan.
- **secrets-guard / light-lint**: per-agent PreToolUse/PostToolUse hooks.

## Pointers

- The spec: `AGENTS.md`. The graph: `map.yaml`. Why each choice was made: the design docs in
  `~/git/temp_prpomt/` (findings, domains-tools, plan, migration-plan).
- Bootstrap is agent-native — there is deliberately no bootstrap script.
