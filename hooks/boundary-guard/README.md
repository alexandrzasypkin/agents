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

## Configure
Copy `patterns.conf.example` → `patterns.conf` and fill it from this project's `boundaries`/`forbidden`:
each line is `<ERE path pattern><TAB><reason>`. Without `patterns.conf` the hook is a **no-op** — it
ships inactive, which is safe but **not done**: an empty `patterns.conf` is a silent no-op that fakes the
guarantee. **Deploying this hook includes seeding `patterns.conf`** — at deploy fill the stack-implied
hard invariants (`wrangler`-generated `worker-configuration.d.ts`, a `migrations/` ledger, `dist/`), add
project-specific ones as artifacts appear; on a **rules refresh** the project agent re-checks it is
non-empty while the hook is wired, and logs the fill in `REGISTRY.md`. Wire the `claude.json` fragment (PreToolUse `Write|Edit`) into `.claude/settings.json`
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
