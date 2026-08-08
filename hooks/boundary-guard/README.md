# boundary-guard (hook)

Mechanically backs a project's **hard path invariants** from `boundaries` / `forbidden`. PreToolUse on
`Write|Edit`: if the target path matches a project-configured pattern, it emits `permissionDecision: "ask"`
so the write **pauses for the user's approval** (not a hard `exit 2` wall — a hard block leaves no door;
see the cf-prod-guard lesson).

## Scope — role-agnostic, on purpose
A hook cannot see **which subagent** is acting, so it enforces **"protect path X"** invariants
(generated files not hand-edited, committed migrations immutable, server-only dirs, `dist/`, etc.),
**NOT per-role write-zones**. Per-role zones stay the soft `boundaries` rule + the lead's arbitration.
"A rule asks, a hook guarantees" — this is the guarantee for the role-agnostic subset.

**It fires on the agent's `Write`/`Edit`, NOT on command output.** `pnpm build` writing `dist/`,
`wrangler types` writing `worker-configuration.d.ts`, `pnpm install` writing the lockfile — all bypass the
hook. So **generated-file** patterns (types / `dist/` / `.wrangler/` / lockfile) add **zero** friction in
normal work and only fire when an agent hand-edits a generated file — which is always a mistake, so give
those `deny`, not `ask` (there's no legitimate hand-edit; the user is never prompted). By contrast, a
**migrations-immutable** pattern `migrations/[0-9]+_.*\.sql$` matches a *new* file too — by path you can't
tell "editing committed `0003`" from "creating `0042`", so it would prompt on every new migration. Don't
add it as a plain pattern: leave migration immutability to the `sql-migrations` rule, or gate only when the
target already exists (`[ -e ]`), not by `Write` vs `Edit` (a `Write` can overwrite an existing file).

## Configure
Copy `patterns.conf.example` → `patterns.conf` and fill it from this project's `boundaries`/`forbidden`:
each line is `<ERE path pattern><TAB><reason>`. Without `patterns.conf` the hook is a **no-op** — it
ships inactive, which is safe but **not done**: an empty `patterns.conf` is a silent no-op that fakes the
guarantee. **Deploying this hook includes seeding `patterns.conf`** — at deploy fill the stack-implied
hard invariants (`wrangler`-generated `worker-configuration.d.ts`, a `migrations/` ledger, `dist/`), add
project-specific ones as artifacts appear; on a **rules refresh** the project agent re-checks it is
non-empty while the hook is wired, and logs the fill in `REGISTRY.md`. Seeding is **autonomous** (project
adaptation — no permission needed to adapt); but since `patterns.conf` gates the **user's own** writes,
surface the path list **once** at seeding for a quick adjust ("these paths will now prompt you") — not a
blocking "may I proceed?". Don't re-ask on later refreshes: a filled config is done; the refresh check is
silent unless it's empty/broken. Wire the `claude.json` fragment (PreToolUse `Write|Edit`) into `.claude/settings.json`
(the bootstrap deep-merge does this). For a hard block instead of a prompt on a specific pattern, change
that path's decision to `"deny"` in `guard.sh` — default is `"ask"`.

## Per-agent install
- **Claude** → merge `claude.json` into `./.claude/settings.json` (`hooks.PreToolUse`, matcher `Write|Edit`).
- **Codex** → merge `codex.toml` into `./.codex/config.toml`. If your codex version honours only
  `"deny"`, the `"ask"` this guard returns is ignored and it degrades to advisory — verify per version.
- **opencode** → copy `opencode.ts` to `./.opencode/plugin/boundary-guard.ts`. opencode can only block
  by throwing (no "ask"), so there it is **advisory** (warns, does not block); it reads the same
  `patterns.conf` from the project root.

Without `patterns.conf` every agent's variant is a no-op.
