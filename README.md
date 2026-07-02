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

By default, skills, subagents, and rules are NOT loaded through Claude's native systems
(`.claude/skills`, `/` slash-commands, the Task subagent registry) — the one exception is spawned
`delegation`, below. They live in `./.agents/` and are found two ways:

- the **pointer** in the project `AGENTS.md` ("rules/skills/agents → `./.agents/`");
- the **chain** in `map.yaml`: a rule names its skill / subagent / MCP, so a skill is pulled in
  *because its rule is active*, not because it sits in a native menu.

Why: this makes the system identical across Claude / Codex / opencode and independent of any
one agent's folder conventions (a project may have no `.claude/` at all). The trade is that the
agent *uses* a skill or role by **reading its file** — portable, but no native `/command` and no
spawn.

**Exception — `delegation` (large projects):** true spawned, isolated, parallel subagents are a
**native** capability that pointer/chain role-files cannot provide. A project that uses `delegation`
keeps its spawnable roster as **native** subagents (`.claude/agents/*.md`, spawnable by
`subagent_type`), not moved to `.agents/`. The portable `.agents/agents/` role-files stay the default
for the non-spawned case. See the `delegation` rule.

The `.claude/` files we otherwise use: `settings.json` (chain hooks, committed) + `settings.local.json`
(personal permissions, gitignored).

## Project settings: `map.yaml` → native config (hooks, MCP, permissions)

Rules, skills, and subagents are *read* from `.agents/` via the pointer. **Runtime wiring —
hooks, MCP, permissions — is different: each agent loads it natively from its own config file**,
so it can't be read from `.agents/`. `map.yaml` is the single logical source (the WHAT); bootstrap
renders it into each agent's native format (the HOW). The agent never reads `map.yaml`.

- **Declared in `map.yaml` (the chain):** a rule names its hooks/MCP — `secrets: {hooks:
  [secrets-guard]}`, `quality-py: {hooks: [light-lint]}`. Agent-agnostic, one source.
- **Rendered per project, conditionally:** bootstrap writes the wiring into the project's native
  files only for the rules/domains that are active. No secrets/code → those hooks aren't attached.
  Native install writes **only to the project**, never to global settings.
- **Per agent (the HOW):**
  - **Claude** — `.claude/settings.local.json`: `permissions` (allow/deny) + `hooks` (JSON;
    `command` → `~/.agents/hooks/<name>/*.sh`).
  - **Codex** — `.codex/config.toml`: `[[hooks.*]]` with `command` + `command_windows`; project-bound
    `[mcp_servers.*]`. Trusted project; merges over `~/.codex/config.toml` (project wins).
  - **opencode** — `opencode.json` (canon `instructions` + `mcp` + `permission`) and
    `.opencode/plugin/*.ts` (hooks as native TS plugins — OS-agnostic, block via `throw`, no "ask").
- **Placement rule** — one test, *is it tied to this project's account / resource / repo?* Yes →
  the project layer (project-bound MCP like cloudflare/gsc, project permissions, project hooks).
  The lone universal exception is **`baseline-guard`**: installed globally **by hand**, it guards
  writes to `~/.agents` itself and sits in no chain. Bootstrap never writes global config.
- **OS handling** is isolated to the bootstrap render (per-machine): the hook script is a single
  POSIX `.sh` (run via Git Bash on Windows); Codex selects per-OS via `command_windows`; opencode's
  TS plugin is OS-agnostic. Otherwise project file contents stay OS-agnostic.
- **Invariant:** only `baseline-guard` is global; everything project-specific renders to the project
  layer, which loads only inside its own folder → no cross-project leakage. A base hook must exit
  cleanly (`exit 0` / no `throw`) when its context doesn't apply.

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

**Required — install the global `hooks/baseline-guard/` into each agent's global config**
(Claude `~/.claude/settings.json`, Codex `~/.codex/config.toml`, opencode
`~/.config/opencode/plugin/`). It makes every write to `~/.agents` need your explicit approval,
so an agent can't silently rewrite the shared baseline that every project copies from. This is the
**one** guardrail bootstrap does NOT install — bootstrap never writes global config — so install it
here, by hand, once per machine (and again whenever you add a new agent). Per-project hooks and
anchors are created by bootstrap, not here.

## How a project is set up (bootstrap)

A fresh agent in an uninitialized folder reads the canon and runs BOOTSTRAP: survey the
domains → deploy `base ∪ domains` chains into `./.agents/` → write runtime anchors and
deep-merge per-agent hook/MCP configs → `git init` + install git hooks + `.gitignore`. From
then on the project is autonomous; it self-configures (pull / install / adapt) and logs *why*
in `./.agents/REGISTRY.md`.

## Guardrails

**Global — installed by hand, once per machine (bootstrap never writes global config):**
- **baseline-guard**: every write to `~/.agents` needs your explicit approval (native ask);
  reading/copying is free. Protects the shared baseline. The sole global guardrail.

**Per-project — rendered from the `map.yaml` chain into the project at bootstrap.** A project's
hooks come from its active rules (declared per rule in `map.yaml`); the specifics live there and in
the bootstrap step, not in this overview.

**Git — installed unconditionally at bootstrap (into `.git/hooks/`):**
- **git-quality-gate**: mandatory pre-commit/pre-push lint/type/test + an unconditional secret scan.

## Pointers

- The spec: `AGENTS.md`. The graph: `map.yaml`. Why each choice was made: the design docs in
  `~/git/temp_prpomt/` (findings, domains-tools, plan, migration-plan).
- Bootstrap is agent-native — there is deliberately no bootstrap script.
