# baseline-guard

A **global** PreToolUse hook: an agent may **read/copy from** `~/.agents` freely (bootstrap
needs that), but **writing** to it needs your explicit approval. On a write the hook returns
`permissionDecision: "ask"`, so the agent surfaces the action and you approve or refuse it
natively in the conversation. No env flags — permission is your spoken yes.

This guards the shared baseline (canon + rules) from silent edits, including the agent
rewriting its own canon. It complements the canon's soft autonomy boundary ("change the
baseline only by agreement") with a hard gate ("a rule asks, a hook guarantees").

## What it blocks
A write/delete whose target resolves under `~/.agents/` — via Edit/Write/MultiEdit/apply_patch,
or a shell command (`rm`/`mv`/`>`/`tee`/`sed -i`/`cp … ~/.agents`, etc.). A project's local
`./.agents/` is NOT affected (only the global library). Reads and `cp ~/.agents/… dest` are free.

## Install — GLOBAL (not per-project)
- **Claude** → merge `claude.json` into `~/.claude/settings.json` (`hooks.PreToolUse`).
- **Codex** → merge `codex.toml` into `~/.codex/config.toml`.
- **opencode** → copy `opencode.ts` to `~/.config/opencode/plugin/baseline-guard.ts`
  (opencode has no native "ask" from a plugin, so there it hard-blocks; disable the plugin to
  edit the baseline).

`guard.sh` is the shared detector. python3 absent → fail-open (allow).
