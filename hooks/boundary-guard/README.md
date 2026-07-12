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
each line is `<ERE path pattern><TAB><reason>`. Without `patterns.conf` the hook is a **no-op**, so it
ships safe/inactive. Wire the `claude.json` fragment (PreToolUse `Write|Edit`) into `.claude/settings.json`
(the bootstrap deep-merge does this). For a hard block instead of a prompt on a specific pattern, change
that path's decision to `"deny"` in `guard.sh` — default is `"ask"`.
