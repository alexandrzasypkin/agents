# Canon `~/.agents/AGENTS.md` — global, not a project file

## Purpose

**The rule is the entry point.** The user picks a rule — and **bootstrap** deploys its
chain (skill, agent, MCP) by the link map in `~/.agents`. The rule itself deploys
nothing: it declares its dependencies, and bootstrap deploys them. The user does not
assemble a set by hand — one choice brings a consistent chain. This is what delivers
uniformity across all described scenarios.

**Provided** the library (`~/.agents/{rules, skills, agents, templates}`) is filled
with base rules and their tools, and their links are described in the map `map.yaml`.

### Uniformity mechanism

When a new project is initialized:

1. **The skeleton is copied whole** — the `~/.agents/` folder structure is carried into
   the project as is (an empty frame).
2. **A survey determines the domains** — the user multi-selects domains. The domain list
   lives in `map.yaml` (`types`), not here — it is data, not mechanism.
3. **The map deploys the chains** — each selected domain contributes its rule set via the
   `types` block in `map.yaml`, unioned over the always-on `base`; for each rule in the
   resulting set its chain is read, and the linked skills, agents, and MCP are copied into
   the project by value.
4. **The project becomes autonomous** — all dependencies are pinned locally, the
   version is controlled via git.

Result: the rule set = `base` ∪ the rules of the selected domains. Two projects that
select the same domains get the same linters, formatters, hooks, and pipelines. Uniformity
is delivered not by manual choice, but by the **link map** in the library.

---

This is the **global** canon, not a project file. It lives at `~/.agents/AGENTS.md`,
is attached via symlinks, and is loaded into every session, including in an empty
folder. The project-level `./AGENTS.md` is a **different file**: bootstrap creates it,
and it holds the pointer and the state of the specific project. Same name, different
roles — the global canon describes bootstrap, the project one records what is attached
to the project. It is attached like this:

```
ln -s ~/.agents/AGENTS.md ~/.codex/AGENTS.md
ln -s ~/.agents/AGENTS.md ~/.claude/CLAUDE.md
```

Only the **canon** is linked globally — by these two symlinks. The other library
folders (`rules/`, `skills/`, `agents/`, `templates/`, `plans/`) are not linked
globally: they are copied into the project at initialization.

`ln -s` works in a bash environment (Linux, WSL2, Git Bash). On native Windows
(PowerShell/CMD) a symlink is created via `mklink` and requires Developer Mode or
administrator rights — so the initial setup of `~/.agents` is more convenient from
bash (WSL2/Git Bash) or via a separate cross-platform initializer script.

The canon does two things: it states the **directive** about where typical behavior
lives and how it is pulled into a project, and it describes **BOOTSTRAP** — how to run
the survey at initialization. The rules themselves are not stored in the canon as text,
and the canon contains no executable logic — only the directive and the bootstrap
description; execution lives in the library.

### Platform: a single path

The path `~/.agents` is written the same way on Linux, WSL2, and Windows — no OS
branching is needed in the instructions. Physically `~` resolves to different places:
WSL2 → `/home/<user>/.agents`, Windows-native → `C:\Users\<user>\.agents`.
Running agents in a single environment (WSL2) is recommended — then there is one folder.
If both are used, keep `~/.agents` in sync across both home directories.

(UTF-8 encoding and LF line endings are a project-level concern: `.gitattributes` and
`.editorconfig` are created at bootstrap step 5, if `git init` was performed.)

---

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

### `map.yaml` schema

The key is a rule name; under it are listed the dependencies of its chain. `base` is a
top-level list of always-on rules (applied unconditionally). `types` holds the selectable
domains the survey multi-selects. The two are separate keys on purpose: `base` is never a
choice, the domains always are.

```yaml
# ~/.agents/map.yaml — ABBREVIATED SCHEMA EXAMPLE, illustration only.
# [!] NOT the real data. The actual rules / base / domains live in ~/.agents/map.yaml —
#     bootstrap MUST read that file. Do NOT take the base/types entries below as the real set.
# All values are arrays of strings (file/folder names in the corresponding folder).
# If a rule is listed in `base`/`types` but absent from `rules` — skip it with a warning.
rules:
  md2pdf:
    skills:    [md2pdf-convert]   # from ~/.agents/skills/
    agents:    [doc-converter]    # from ~/.agents/agents/
    mcp:       [pandoc-mcp]        # MCP server names
    templates: [pdf-style]         # from ~/.agents/templates/
  quality-py:
    skills:    []                 # CLI tools (ruff/pyright/pytest), no skill needed
    agents:    []
    mcp:       []

base: [rule-format, proof-loop, secrets, git-discipline]   # always-on, NOT selectable

types:                            # selectable domains — EXAMPLE subset only; the real map.yaml lists ALL domains
  coding:   [quality-py]
  research: [md2pdf]
  office:   [md2pdf]
# Final rule set = base ∪ rules of the selected domains.
```

### `mcp-configs.yaml` schema

The map stores only MCP names; their configurations are here, by name. Bootstrap takes the name
from the map and the config from here; **project-bound** MCP it deploys into the agents' runtime
formats, **global-infra** MCP it leaves at the machine level (see the two classes below).

This file is a **portable recipe, not frozen machine state**. Env-specifics (absolute paths,
ports, whether a server is running) are NOT hardcoded — bootstrap resolves them by inventorying
the environment.

**Two classes — the same global/local split as hooks & permissions** (*is the MCP tied to THIS
project's account / resource / repo?*):
- **GLOBAL infra** — shared, tied to no project (e.g. `playwright`, a shared browser server).
  Installed **once per machine** at Setup (like `baseline-guard`) into each agent's GLOBAL config.
  Bootstrap does **NOT** render it into project configs — a project that needs it simply USES the
  global server. Marked `scope: global` in the recipe.
- **PROJECT-BOUND** — tied to an account/site/repo (cloudflare, gsc, codegraph). Rendered
  per-project into the project's native MCP config and recorded in REGISTRY.

So bootstrap writes per-project **only project-bound MCP**; shared infra stays machine-level (never
duplicated into `./.mcp.json` / `./.codex/config.toml`).

**Local server vs network MCP (within global infra).** A global-infra MCP is either a **local
capability** (browser, files, code index) or a **remote cloud service** — decide by two questions:
1. *Local capability, used often / interactively / needs shared warm state?* → run it as **ONE
   persistent local server**, every agent connecting by localhost URL (e.g. playwright `:8931`
   `--shared-browser-context`). Localhost ≈ 0 latency, a warm logged-in browser, no per-session cold
   start → **fewer tokens** than spawning stdio each session. Cost: the server must stay up (machine
   service/autostart). **The ladder (both Claude & codex):** (a) connect to `:8931`; (b) if down —
   **ENSURE-SERVER**: install the binary when missing (`npm i -g @playwright/mcp`) and start it;
   (c) if it still can't come up (install fails, offline, no permission) — **fall back to a
   per-session stdio spawn** (`npx @playwright/mcp@latest`, or the `playwright-mcp` binary; native
   Windows `cmd /c npx`), self-contained and costlier but always works. Never silently give up.
2. *Cloud-account data with no local form (cloudflare, gsc, gmail, github)?* → a **network/remote
   MCP** (project-bound, OAuth/key, REGISTRY) — network latency + round-trip tokens are the price of
   data that only lives remotely.
A rare local capability can stay a stdio spawn (zero-setup); reserve a persistent server for the
frequent/interactive ones (this is why the shared `:8931` server beats a per-session spawn).

**Per-OS launcher resolution (npx/node stdio MCP).** When a stdio MCP's command is `npx`/`node`,
Node's `child_process.spawn` cannot resolve `npx.cmd` on native Windows → `spawn npx ENOENT`. So
whoever writes it (the machine-level global install, or a project-bound npx MCP): **POSIX** (Linux /
macOS / WSL2 / Git-Bash) renders the command **as-is**; **native Windows** wraps it `cmd /c npx -y
<pkg>` (or the absolute `…\npx.cmd`). Windows-only flags (e.g. playwright's `--browser chrome`, which
registry-resolves Chrome) are added there only, never on POSIX.

```yaml
# ~/.agents/mcp-configs.yaml — two classes:
playwright:           # GLOBAL infra — installed once per machine, NOT rendered per-project
  scope: global       #   Claude/opencode stdio `playwright-mcp` (POSIX) / cmd /c npx (Windows);
                      #   codex remote http://localhost:8931/mcp (streamable-HTTP /mcp, not /sse)
# PROJECT-BOUND (rendered per-project, logged in REGISTRY): cloudflare / gsc / codegraph
```

### Hooks

Deterministic guardrails — *a rule asks, a hook guarantees*. A rule is a soft instruction
the agent may forget on a long session; a hook fires on an event, mechanically. Two
delivery mechanisms:

- **Git hooks** (`pre-commit` / `pre-push`) — universal shell scripts in `.git/hooks/`,
  identical for every agent and for no-agent use. They carry the **main** quality gate
  (lint / typecheck / tests, dispatched by project language) plus a staged-secret scan.
  Installed **unconditionally** at bootstrap (mandatory — BOOTSTRAP step 5); the main check
  cannot be forgotten because it runs on the git event.
- **Agent hooks** — fire on the agent's tool calls; **per-agent format** (no cross-agent
  standard, unlike skills):
  - Claude: `settings.json` `hooks` (PreToolUse / PostToolUse; exit 2 or JSON `permissionDecision` to block);
  - Codex: `config.toml` hooks (event → matcher → handler; JSON on stdin; return JSON `permissionDecision:"deny"` to block — `async` is ignored, all hooks block);
  - opencode: a JS/TS plugin under `.opencode/plugin/` exporting `tool.execute.before` (throw to block) / `tool.execute.after`.

  Two baseline agent hooks: a **secrets-guard** (PreToolUse — block read/write/edit of secret
  files; ties to the `secrets` rule) and a **light-lint** (PostToolUse — fast, non-blocking
  lint of the just-edited file; ties to `quality-*`).

The `hooks/` library folder holds the definitions (universal git scripts + per-agent
agent-hook recipes). Bootstrap installs git hooks (step 5) and writes agent hooks into each
agent's config/plugin (step 4). Like `mcp-configs.yaml`, agent-hook recipes are a **portable
intent** — env-specifics resolve at bootstrap.

All hook scripts (the git gate and the secrets-guard/light-lint helpers) are POSIX shell —
they run on Linux, WSL2, macOS, and Windows via Git Bash (Git for Windows bundles `sh`, so
git hooks execute). On native Windows without a POSIX shell the agent adapts per its
environment inventory (e.g. Claude's `shell: powershell`); no per-OS matrix is shipped.

---

## BOOTSTRAP (only in an uninitialized folder)

### Trigger condition

A folder is considered **uninitialized** if neither it nor anything above it in the tree
(up to the root) has **`./AGENTS.md` or `.git`**. Check upward through the tree exactly —
otherwise a new subfolder inside an already-initialized project would be falsely taken
for a new project.

- Condition met → initialization mode, steps below.
- Condition not met → the project already exists, this section is ignored, normal work.

### Initialization steps

[CRITICAL] **Finish initialization before ANY project work.** The survey (step 2) is **not** the finish
line — steps 3–6 (deploy the chain, write the runtime anchors, git + hooks, report) must complete **in
the same turn, before** you research, write code, or answer the substantive request. If the user's first
message is already a task, **bootstrap first, then do the task**. Asking about domains and then jumping
straight into the work leaves the project unconfigured, and the work has to be redone later against the
structure that should have been there (a real incident). The **step-6 report is the completion signal** —
until it is printed, initialization is not done and no project work starts.

Layout after bootstrap — runtime anchors in the root (agents require them there),
all other infrastructure under `./.agents/`:

```
project/
├── AGENTS.md                                         # SHARED (first agent to run): project's own source of truth (real file)
├── CLAUDE.md  .claude/settings.json  .mcp.json       # Claude's OWN (when Claude runs): symlink→AGENTS.md; hooks; project-bound MCP
├── .codex/config.toml                                # codex's OWN (when codex runs): hooks + project-bound MCP
├── opencode.json  .opencode/plugin/                  # opencode's OWN (when opencode runs): canon pointer + MCP; TS hook plugins
│                                                     # each agent writes ONLY its own; never another agent's
├── .agents/                         # infrastructure, does not clutter the root
│   ├── map.yaml  mcp-configs.yaml   # snapshot of the graph and configs (copy of the library)
│   ├── REGISTRY.md                  # project adaptation log (why); empty if no changes
│   ├── rules/ skills/ agents/ templates/ hooks/ runbooks/ plans/{active,done}/   # copy of the library (EDITABLE)
│   └── generated/                   # bootstrap output (do not edit)
│       └── .agents.lock.yaml        # snapshot: what was built and from which version
├── docs/                            # MANDATORY (project-docs, base): source of truth + decisions/ (ADR) + backlog index; or reuse existing docs/|wiki/|guide/
└── …                                # the project's OWN existing files (src/, package.json, …) — bootstrap does NOT create these
```

`~/.agents` (source, immutable) and `./.agents` (copy in the project, editable) —
same name, different places. Steps:

1. **Lay down the `./.agents/` skeleton.** The files `map.yaml` and `mcp-configs.yaml`
   are copied (snapshot of the graph and configs), an empty `./.agents/REGISTRY.md` is
   created (adaptation log, filled in over the course of work), plus an **empty**
   skeleton of folders (`rules/`, `skills/`, `agents/`, `templates/`, `hooks/`, `runbooks/`, and
   `plans/` with its `active/` and `done/` subfolders) and an
   empty `./.agents/generated/`. `runbooks/` carries its `README.md` (standing operational
   procedures — deploy/restore; see `.agents/runbooks/README.md`), filled per-operation as the
   project ships, not by the map. The folders are empty — they are filled at step 3 by
   the map. The project copy is **editable** (unlike the immutable `~/.agents`). The root stays clean.
   **Also lay down the docs skeleton (MANDATORY — `project-docs` is base):** `docs/` (source of truth)
   + `docs/decisions/` (ADR archive) + a backlog index (`docs/TODO.md`, or a root `ROADMAP.md`). If the
   project **already has** a docs folder (`docs/`, `wiki/`, `guide/`, …), **use it — do not impose a
   name** (`user-docs`), and just add the missing pieces (e.g. `decisions/`, the backlog) inside it.
   `context/` (consumed inputs) and `content/` (non-dev deliverables) are **not created empty** — they
   appear **when the project needs them** (`context/` on the first input material; `content/` for the
   `content` domain / `content-vault`). Docs are agent-maintained **infrastructure, not project source**. Apart from the runtime anchors,
   the `./.agents/` skeleton, and this docs skeleton, bootstrap never creates or edits the project's
   own source (no `src/`, `package.json`, etc.); those belong to the project and are left untouched.

2. **Survey.** The main question — the project's **domains**: a **multi-select** from the
   domains in `./.agents/map.yaml` (`types`). Do not hardcode the domain list here — it is
   data and lives in the map. This is the `planning` meta-step: a dialog that combines the
   chosen domains (a project may be multi-domain, e.g. coding+web+devops). The always-on
   `base` is added unconditionally — it is not one of the selectable domains.
   Clarify: which MCP to attach — show the list of names from `./.agents/mcp-configs.yaml`
   (the local copy); if the user is unsure — offer a preset by domain. Whether environment
   variables (`PYTHONPATH`, etc.) and extra skills are needed. Do not impose — the user
   is free to choose their own. **Do NOT ask "which agents will work in the project"** — an agent
   configures only itself (step 4); another agent's environment is activated by running that agent.

3. **Fill `./.agents/` and write the snapshot.** Resolve the rule set = `base` ∪ the rules
   of the selected domains (from `./.agents/map.yaml`). For each rule in that set,
   `./.agents/map.yaml` (the local copy) is read, and into `./.agents/{rules,skills,agents,templates,hooks}`
   the rule itself and its linked chain are copied. Names in the map are files or folders
   in the corresponding library folder: a file is copied with its extension, a folder
   recursively whole. MCP names are resolved into an in-memory structure during bootstrap
   from `./.agents/mcp-configs.yaml`; **only project-bound** ones are deployed at step 4 into the
   per-agent formats (`scope: global` infra like playwright is machine-level — used, not rendered
   per-project). A snapshot (what was built and from which version) is written to
   `./.agents/generated/.agents.lock.yaml`. Copy by value (not a symlink).

4. **Create the runtime anchors — SHARED once; per-agent config ONLY for the running agent.**
   **Shared (whichever agent bootstraps first creates it; all agents reuse it):** `./AGENTS.md` —
   the project's OWN source of truth (pointer + behavioral rules + self-config), a **real file**
   (codex and opencode read it natively). Plus the `.agents/` skeleton (steps 1/3) and git + hooks
   (step 5).
   **Per-agent — an agent writes ONLY its OWN native config, never another agent's.** An agent is
   part of the environment and owns its own format; it renders its own MCP/hooks from the chain into
   its own file. Another agent's environment is **activated by running that agent**, which then
   self-configures its own part (see self-config). So Claude does NOT write `.codex/config.toml`,
   codex does NOT touch `.claude/`, and the survey does **not** ask "which agents". Each agent creates
   its own file only when there is content for it (hooks / MCP / permissions); rules and skills stay
   in `.agents/`, read via the pointer, never rendered here:
   - **Claude** (when Claude runs) → `./CLAUDE.md` (symlink → `AGENTS.md`, the only symlink),
     `./.claude/settings.json` (chain hooks), `./.mcp.json` (project-bound MCP), and **the native-memory
     signpost** `~/.claude/projects/<project-path-slug>/memory/MEMORY.md` (slug = the project's absolute
     path with `/`→`-`) — written as the redirect signpost (empty of content, maps each knowledge kind to
     its repo home; see `project-docs`). This is the one legitimate `~/.claude` write and the direct
     bootstrap guard against the recurring "project knowledge dropped in native-memory" leak.
   - **codex** (when codex runs) → `./.codex/config.toml` (chain hooks + project-bound MCP; trust).
   - **opencode** (when opencode runs) → `./opencode.json` (canon pointer + MCP) and
     `./.opencode/plugin/*.ts` (hooks).
   The per-agent formats:

   | File | Purpose |
   |------|---------|
   | `./AGENTS.md` | Autonomous project source of truth. Read natively by codex and opencode. Holds the pointer and the self-configuration rule (below). |
   | `./CLAUDE.md` | A **symlink → `./AGENTS.md`** (next to it). Needed because Claude Code does not read `AGENTS.md` natively — only `CLAUDE.md`; the link feeds it the project's own `AGENTS.md`. The global canon arrives separately via the global `~/.claude/CLAUDE.md` symlink. |
   | `./opencode.json` | Root required (opencode searches upward to the git root). `instructions` (the **OS-resolved** absolute path to the canon — `/home/<user>/.agents/AGENTS.md` on Linux/WSL2, `C:\Users\<user>\.agents\AGENTS.md` on Windows; resolve it for this machine, do not copy the example literally) + an `mcp` block. Returns the canon to context and does not expose `~`. **Written by opencode itself when it runs** (never by another agent). |
   | `./.mcp.json` | **Project-bound** MCP for Claude Code (read separately from `CLAUDE.md`). **Only if the project has project-bound MCP** — shared infra like playwright is global, not written here. |
   | `./.codex/config.toml` | **Project-bound** MCP for codex: `[mcp_servers.<name>]`, plus chain hooks. Loaded only if the project is "trusted" (codex asks on first run). codex merges it with the global `~/.codex/config.toml` — project values take priority; the global `playwright-shared` is used from there, not duplicated here. **Written by codex itself when it runs** (never by another agent), when it has chain hooks or project-bound MCP. |
   | `./.claude/settings.json` | **Committed** Claude settings — the project's chain **hooks** land here so they are git-pinned (a clone gets them). **Only if the project has chain hooks (usually yes — `secrets` is base).** |
   | `./.claude/settings.local.json` | **Gitignored, personal** Claude settings — only project **permissions** (allow/deny). NOT hooks: `**/.claude/settings.local.json` is git-ignored by convention, so hooks placed here would not be pinned (a clone would lose them). opencode permissions live in `opencode.json`, codex in `config.toml`. **Only if there are project-specific permissions.** |

   If an anchor already exists — **do not overwrite**, print a warning
   ("file X already exists, skipped").

   Formats (agent-specific, so as not to hallucinate the structure):

   ```jsonc
   // ./opencode.json — the mcp key (type local/remote; command is an array)
   // instructions: OS-resolved absolute canon path (Windows: C:\Users\<user>\.agents\AGENTS.md)
   {
     "instructions": ["/home/<user>/.agents/AGENTS.md"],
     "mcp": { "pandoc-mcp": { "type": "local", "command": ["pandoc-mcp"], "enabled": true } }
   }

   // ./.mcp.json — MCP for Claude
   { "mcpServers": { "pandoc-mcp": { "command": "pandoc-mcp", "args": [] } } }

   // ./.claude/settings.json — COMMITTED: chain hooks (so they are git-pinned)
   { "hooks": { "PreToolUse": [ { "matcher": "Read|Edit|Write|Bash",
       "hooks": [ { "type": "command",
         "command": "bash \"$CLAUDE_PROJECT_DIR/.agents/hooks/secrets-guard/guard.sh\" --claude" } ] } ] } }

   // ./.claude/settings.local.json — GITIGNORED, personal: permissions only (no hooks)
   { "permissions": { "allow": ["Bash", "Read", "Write"] } }
   ```
   ```toml
   # ./.codex/config.toml — MCP for codex (project-scoped, trusted)
   [mcp_servers.pandoc-mcp]
   command = "pandoc-mcp"
   args = []
   ```

   **Config assembly (uniform across agents).** Hooks are attached **by the `map.yaml` chain**
   (`secrets → secrets-guard`, `quality-* → light-lint`) — a project gets a hook only when its
   rule is active. Each hook in `./.agents/hooks/<name>/` ships per-agent fragments —
   `claude.json`, `codex.toml`, `opencode.ts` — whose command points at the project's **own**
   copied script: `bash "$CLAUDE_PROJECT_DIR/.agents/hooks/<name>/…sh"` (Claude), a project-relative
   `bash ".agents/hooks/<name>/…sh"` (codex). `bash <posix-path>` is portable on Windows under Git
   Bash, so no per-OS variant is needed. When several fragments target one agent file — permissions,
   MCP, hooks — bootstrap **deep-merges**, it does not overwrite: object keys union, arrays append
   (Claude `settings.json` `hooks.PreToolUse[]`; codex `config.toml` repeated
   `[[hooks.PreToolUse]]`). opencode keeps each hook as its own `.opencode/plugin/<name>.ts`
   (native TS, no merge) and merges only MCP/permissions into `opencode.json`. **Claude split:
   chain hooks go into the COMMITTED `.claude/settings.json` (so they are git-pinned); only personal
   `permissions` go into the gitignored `.claude/settings.local.json`** — otherwise a clone loses the
   hooks. **`baseline-guard` is NOT rendered here** — it is the one global, hand-installed guardrail
   (see README Setup); only chain hooks land in the project. If a target file already exists — merge into it, never clobber
   an existing block (same rule as the anchors above).

5. **`git init` + install git hooks (mandatory).** `git init` only if `.git` is not found
   above in the tree (do not create a nested repository). **`.gitignore` — ENSURE the baseline secret +
   artifact ignores ALWAYS** (`secrets` is base/[CRITICAL]: a secret must never be committable): on a
   fresh `git init`, copy the `templates/gitignore` baseline; on an **existing repo (migration), MERGE
   the missing baseline lines** into the current `.gitignore` (append what is absent — never clobber),
   extended per project per `env-setup`. `.gitattributes` and `.editorconfig` (LF, UTF-8) are created
   only on a fresh `git init` (otherwise they'd override a parent repo's convention) — before the
   first commit. The `.agents/generated/.agents.lock.yaml` is committed (provenance), not ignored.
   **Lint/typecheck exclude (when the project has JS/TS quality tooling):** the `.agents/` layer ships
   `.ts` hook fragments (`opencode.ts`) that sit outside the project's `tsconfig` scope — MERGE
   **`.agents/**`** (and `.claude/**`) into the project's eslint `ignores` (and `tsconfig` `exclude` if
   its `include` globs `**/*.ts`), appending, never clobbering. Skip it and a type-aware lint/`tsc` gate
   parse-errors on the new layer (see `quality-js`). Same merge discipline as the `.gitignore` step.
   Then **install the git hooks
   unconditionally** (not a survey option): `pre-commit` (light gate on staged files + secret
   scan) and `pre-push` (full quality gate), dispatching to the active `quality-*` rules by
   project language. The main lint/test gate runs on the git event, so it cannot be forgotten.

6. **Report** — print the list of what was created. Example:
   ```
   Created:
   - root:      ./AGENTS.md ./CLAUDE.md ./opencode.json ./.mcp.json
                ./.codex/config.toml ./.claude/settings.local.json
   - .agents/:  map.yaml mcp-configs.yaml
                rules/md2pdf.md skills/md2pdf-convert.md
                agents/doc-converter.md templates/pdf-style/
   - generated: ./.agents/generated/.agents.lock.yaml
   ```
   From here the project is self-sufficient for work.

### Snapshot `.agents.lock.yaml`

Written at step 3. Records what was built and from which library version — gives
reproducibility and provenance without reaching into `~/.agents`:

```yaml
# ./.agents/generated/.agents.lock.yaml
source: /home/<user>/.agents   # absolute path (not ~); OS-resolved (Windows: C:\Users\<user>\.agents)
commit: abc123                # git rev-parse HEAD (if ~/.agents is a git repo; otherwise empty or a date)
generated_at: 2026-06-26T12:00:00Z
domains:  [research]          # multi-select; base is always included on top
rules:    [md2pdf]
skills:   [md2pdf-convert]
agents:   [doc-converter]
mcp:      [pandoc-mcp]
templates:[pdf-style]
```

### Autonomy and the link to `~/.agents`

After bootstrap the project is **fully autonomous**: the rules, skills, agents, runtime
configs, and the graph snapshot (`./.agents/map.yaml`, `./.agents/mcp-configs.yaml`) are
copied into the project. `~/.agents` is not needed for work or for reading the project's
own links — everything is local, less confusion.

The library `~/.agents` is needed only when deploying a **new** rule that is not yet in
the project: its files and its chain are by nature taken from the library. The logic is
the same as in the pointer: the local copy `./.agents/` first, and only for something new —
a fresh copy from `~/.agents`. After deployment, the new item is also appended to the
local copy of the map. What was built at the moment of initialization is recorded in
`.agents.lock.yaml`.

[CRITICAL] **Refreshing a library file into a project MERGES — never blind-overwrites.** A project copy
may differ from the library because the **project appended to it** (an agent role carrying a
"Project delta" write-zone, a rule with project specifics, a hook README with provenance) — not because
the library moved ahead. Before copying: check whether the library file actually changed
(`git log -- <path>` in `~/.agents`). If the difference is the project's own addition, **keep it** — take
the library body and re-apply the project delta. A blind `cp` silently destroys project memory. (Real
incident: a roster refresh wiped the per-role write-zones and project checklists of `reviewer`/`docs`/`e2e`
in two projects, while the library's `agents/` had not changed at all — recovered only because the
projects had committed them. Hence also: **commit the project's memory**, see `project-docs`.)

**The safe merge is a 3-way merge on the lock commit — not line-guessing.** `.agents.lock.yaml` records
the library `commit:` the project was built from = the merge **base**. So: `base` = `git -C ~/.agents show
<lock>:rules/<f>`, `ours` = the project copy, `theirs` = the library HEAD; `git merge-file ours base theirs`
folds in the library's changes, **keeps the project delta automatically**, flags only real conflicts
(resolve with the user). No delta → clean update. Then bump the lock `commit`, update `map.yaml` if chains
changed, log in `REGISTRY.md`. No usable lock commit (pre-lock project) → fall back to the manual reconcile
above. This is how a project stays current WITHOUT an external sweep: the agent already in the project,
which knows its own deltas, runs the merge.

**The CHANGED-file trigger.** The one-shot new-rule scan (`find`) catches rules ADDED to the library, never
ones CHANGED after bootstrap — so projects silently drift (real: an outdated `project-docs` `type:`
vocabulary lingered across projects). At session start, in the same one-shot spirit, diff the lock against
HEAD: `git -C ~/.agents log --oneline <lock>..HEAD -- rules skills agents hooks`. Non-empty → surface
"N library files changed since bootstrap: […]; refresh?" and reconcile each file the project HAS via the
3-way merge above. An explicit user request does the same. Agents do NOT auto-refresh — this standing
instruction is what makes them check.

Self-configuration (see the project `AGENTS.md`): if a rule is found in `~/.agents/rules/`
but is absent from the local `./.agents/map.yaml` — take its chain from the fresh
`~/.agents/map.yaml`, deploy it into the project, and append it to the local copy of the map.
A rule already present but **changed** in the library since the lock commit is refreshed by the 3-way
merge above (not re-deployed).

### What to write into the project `./AGENTS.md`

The generated file must contain at least the four blocks below.

`AGENTS.md` is a **thin anchor**: it POINTS to where things live, it does not COPY them. A project may
add a brief block for its core working style (e.g. a large project's delegation model), but even that
**points** to the rule/roster — it does not restate them. Everything else routes to its home and is
referenced from the pointer, NOT written here:
- environment change / attach / prune / **deviation + its WHY** → `REGISTRY.md` — not this file. (The
  "Attached at initialization" block stays a one-time thin snapshot; it does not re-narrate deviations.)
- architecture / data-model / flows → `docs/` (or the project wiki) · a project rule → `.agents/rules/`
  · a decision → `docs/decisions/` · a plan → `.agents/plans/`.
Only project **behavioral lessons** (incident-driven) grow inside this file, in the seed block below.
If a section here restates something that already has a home, it is a leak — move it, leave a pointer.
(Real incident: three sessions in a row dumped adaptations and rule/architecture detail into `AGENTS.md`
instead of routing them; it swelled into a catch-all.)

```markdown
# <Project> — AGENTS.md

## Pointer (where to look, in priority order)
- Rules: first `./.agents/rules/`, then the library `~/.agents/rules/`.
- Skills/agents: first `./.agents/`, then the library.
- Links and MCP configs: first the local `./.agents/map.yaml` + `./.agents/mcp-configs.yaml`; `~/.agents/...` — only to deploy a new rule. The build snapshot — in `.agents.lock.yaml`.
- Adaptation registry: `./.agents/REGISTRY.md` — WHY something was added/changed (the WHAT graph — in `map.yaml`, do not duplicate).
- **[CRITICAL] Plans, docs, and work-artifacts live ONLY in this project** — `./.agents/plans/{active,done}`, `./docs/`, the project tree. **NEVER write them to `~/.claude/`, `~/.codex/`, `~/.config/opencode/`, or any home/global agent folder** (see `project-docs`). **This includes the agent's built-in memory** (Claude Code's `~/.claude/projects/…/memory/` + `MEMORY.md`) — it is a home folder that does NOT travel with the repo, so project-persistent knowledge goes to `AGENTS.md` / `REGISTRY.md` / `docs/`, never native-memory. Scratch/temp → session scratchpad or a gitignored project dir.
- On conflict the project wins (more specific overrides more general).

## Behavioral rules (base seed — expand as you work)
- **Think before coding.** State assumptions; if uncertain, FIRST consult the docs (a rule's
  `description:` trigger + the pointer tell you which one) — ask the user ONLY for what the record cannot
  hold (intent, preference, genuine ambiguity), never for what a rule/doc already answers. Present
  competing interpretations — don't pick silently. Name what's unclear and stop. Push back when a simpler path exists.
- **Read the recorded artifact before acting — don't reset to a clean slate.** Principles and decisions
  are recorded (`AGENTS.md`, `docs/` incl. ADRs in `docs/decisions/`, `REGISTRY.md`, plans) precisely so
  they persist and get applied. Before acting, read what governs the thing and act **from** it — do not
  re-derive, re-ask what is documented, or drift off-principle. Re-asking a settled decision or
  duplicating what the record already resolves nullifies the whole point of recording it (and of this
  memory architecture). Recorded ≠ read: the write only pays off if the next session reads it first. The
  metadata is your INDEX — a rule's `description:` is a trigger ("Apply when …") and the pointer says
  where each kind of knowledge lives, so you find the ONE doc that answers a task without reading
  everything; "didn't know where to look" is not an excuse — that is what the metadata is for.
  **Retrieving is not applying:** a record read but not acted *from* fails exactly like one never read —
  the two read-side misses are *not retrieved* (skipped the index) and *retrieved-but-ignored* (read it,
  drifted anyway). The whole write discipline pays off only on the read.
- **Simplicity first.** Minimum code that solves the problem — no speculative features,
  abstractions, flexibility, or error handling for impossible cases. 200 lines that could be 50 → rewrite.
- **Surgical changes.** Touch only what the request needs; every changed line traces to it.
  Match existing style; don't refactor what isn't broken or delete pre-existing dead code (mention it).
  Remove only the orphans your change created.
- **Reuse before you write — search first.** Before adding a function / helper / type / endpoint /
  util, search for an existing one and reuse or extend it. LSP is the fast tool: workspace-symbol by
  concept, find-references / go-to-definition to see and read what already exists; grep a distinctive
  string when the name may differ; a structural index (code-graph) for cross-cutting spread. Writing a
  fresh block without looking forks a parallel duplicate — cheapest to stop at the one search before
  the write (detail in `code-search`).
- **Comments earn their place — no noise.** A comment explains *why* (a non-obvious constraint,
  a trade-off, a gotcha) — never *what* the code already says. Delete filler: restating the line,
  section banners, changelog/attribution lines (`// added by …`, `// AI-generated`, `// fixed bug`),
  commented-out code, `TODO`s with no owner/issue. A long comment that points to a doc to explain
  what the code does is a smell — the code is unclear; fix the code, don't annotate around it.
  (Same discipline as the no-noise commit rule in `git-discipline`, applied to source.)
- **Goal-driven + verify.** Turn the task into a verifiable goal; brief plan, per-step verification;
  confirm by an independent check, not assertion (see `proof-loop`, `code-review`).
- **Chat answers: structured and plain.** Reply in the chat with structure (short paragraphs, a
  list or a small table when it helps) and **plain language** — lead with the answer, then the why.
  No buzzwords or jargon; a genuine technical term (API, hook, symlink) is fine when it is the
  precise word, not decoration. This governs conversational replies; drafted output documents follow
  `writing-style`.
- **Workspace hygiene — clean up when done.** Don't start or restart servers or spawn background
  processes unless asked; when a task is finished, tidy up — kill the background processes / dev
  servers you started, remove temp/scratch files. Leave the workspace as you found it, plus the
  intended change.
- **Don't block on a slow tool.** If a tool / MCP / index / server doesn't answer within a sensible
  bound (a few seconds), proceed without it and say so — never hang waiting on it.
- **Context economy — one chat, one task.** A session accrues cruft; a long thread with several pivots
  makes the model drift and re-read. Keep a session scoped to ONE goal; start fresh when the goal
  changes, the agent loops, or context is bloated with logs — but stay in one thread when tasks share
  files/contracts or B depends on A. Token discipline, same theme: subagents return a SUMMARY, not raw
  logs, to the parent; don't re-read huge files or re-explain the project (that is what the rules +
  AGENTS.md are for); reasoning on the strong model, mechanics on the cheap one.
  **Compaction is lossy** — before a thread grows long or context is compacted away, write durable
  state OUT to the plan handoff / `REGISTRY.md` / docs, not left sitting in chat; on resume, read that
  record first — a compaction summary is a lossy digest, not the source of truth, so don't re-derive
  from it what the plan already holds (nor trust it to have kept every constraint).

The project agent **expands this section** with project-specific behavioral lessons learned
during work (a living layer — append, don't restate the base). Add a rule **only after a real
incident** — a problem that actually happened — not speculatively: each line should trace to an
incident, not a guess (this keeps the layer lean). Behavioral lessons go here; tool/skill/rule
adaptations go to `REGISTRY.md`.

## Self-configuration (adapt and explain)
`~/.agents` provides a minimal shared baseline; adapting to the project is standard work. **The
self-config ladder — (1) use the local `./.agents/` copy · (2) pull a NEW rule + chain from the baseline ·
(2b) refresh a CHANGED library copy via a 3-way merge on the lock commit · (3) escalate via `research` —
lives in the canon** (`~/.agents/AGENTS.md`, "Autonomy and the link to `~/.agents`"), loaded every session
via the global symlink. **Do not restate the steps here — they drift per project;** follow them from the
canon. This section records only THIS project's self-config *specifics* (deviations, project-local rules).

**Activate an agent by running it.** An agent entering an already-initialized project (`.agents/` +
`AGENTS.md` present) that has **no native config of its own** renders its own part from the chain —
its hooks/MCP into its own file (Claude → `.claude/settings.json` + the `CLAUDE.md` symlink; codex →
`.codex/config.toml`; opencode → `opencode.json` + `.opencode/plugin/`), logged in REGISTRY. No agent
sets up another agent's environment; each activates itself the first time it runs there.

Accounting: `./.agents/map.yaml` = WHAT is attached (the graph). `./.agents/REGISTRY.md` = WHY
(change log: what, version/source, date, rationale). Write ONLY changes —
no changes, the file is empty. Do not duplicate the graph in REGISTRY. Own skills
(created via `/`) are also recorded in REGISTRY; author them via the `skill-creator`
library skill (draft → forward-test → iterate).

Autonomy boundaries:
- adapting the PROJECT (layers 1–3) — without asking, standard;
- changing the BASELINE `~/.agents` — only by agreement with the user.

[CRITICAL] Any attach/install/replace — with an explanation in REGISTRY.md.
Without the record, the next session does not know why the project environment is the way it is.

## Attached at initialization
- Library version: from `.agents.lock.yaml` (commit or date)
- Domains: <multi-select> (always-on `base` included on top)
- Rules: <list from the library>
- Skills / agents: <lists>
- MCP: <list; configs from `mcp-configs.yaml` → `.mcp.json` / `opencode.json` / codex config>

Do not duplicate the contents of `map.yaml` **or `REGISTRY.md`** — this block is a one-time thin snapshot
(version / domains / rule+skill+agent counts). Links come from `./.agents/map.yaml` via the pointer; the
WHY of any deviation lives in `REGISTRY.md` — point to it, do not restate it here.
```

---

## The library `~/.agents/`

```
~/.agents/
├── AGENTS.md         # this canon (directive + BOOTSTRAP)
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
