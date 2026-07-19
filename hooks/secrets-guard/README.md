# secrets-guard

A PreToolUse agent hook. **Goal: a secret VALUE must never reach the chat/transcript.** It is *not*
a blanket ban on touching secret files — the `secrets` rule explicitly sanctions using a value
**through a pipe**, and `cf-secrets` is built on that. So the guard blocks only what would surface
the value.

Secret files: `.env`, `.env.*` (except `*.example/.sample/.template`), `.dev.vars`, `.secrets`,
`*.pem`, `id_rsa`/`id_ed25519`.

## What is blocked vs allowed

| | |
|---|---|
| **DENY** — `Read`/`Write`/`Edit` tool on a secret file | Read returns the content into the transcript; Write/Edit carries the value in the tool call. |
| **DENY** — a shell command whose **stdout** would carry the content | bare `cat/head/grep/base64 .env`, or a pipeline whose **last** stage is a printer/text-filter (`… \| grep KEY`, `… \| cut -d= -f2-`) — its stdout returns to the agent. |
| **ALLOW** — the sanctioned pipeline | `grep '^KEY=' .dev.vars \| cut -d= -f2- \| <consumer>` — the value flows into a consumer, never to stdout. |
| **ALLOW** — redirect to a file | `… > /tmp/secret_val` (then `shred -u` it). |
| **ALLOW** — metadata-only ops | `ls`, `stat`, `test`, `wc`, `du`, `find`, `cp`, `mv`, `rm`, `chmod`, `git`, `shred` — they never print content. |
| **ALLOW** — templates | `.env.example`, `.sample`, `.template`. |
| **ALLOW** — a provably non-printing final stage | exit-code/count only (`grep -q`, `grep -c`) or key **NAMES** only (`cut -d= -f1`, `awk -F= '{print $1}'`) — checking *which* keys exist never prints a value. |

Only the **final** pipeline stage matters — that is what returns to the agent.

## Why a whitelist, and why not "ask"

The name-listing allowance is a **fail-closed whitelist**: only the exact forms above match. A
near-miss — `cut -d= -f1,2`, `cut -d= -f2-`, `awk '{print $2}'`, `grep` without `-q`/`-c` — does **not**
match and falls through to DENY. Widen it only with a form you can prove prints no value.

An "ask" tier for ambiguous filters was considered and **rejected**. Approving such a command *runs*
it, and its stdout is then already in the transcript — the leak is irreversible, and an approval
prompt on an ambiguous filter is a ~90% leak. A false DENY costs one rephrase; a false ALLOW cannot
be undone. Hence: prove it safe (whitelist) or deny it.

## Per-agent install (bootstrap, step 4)
- **Claude** → merge `claude.json` into `./.claude/settings.json` (`hooks.PreToolUse`) — the COMMITTED
  file, so the hook is git-pinned (`settings.local.json` is gitignored; personal `permissions` go there).
  The command runs `guard.sh --claude` (exit 2 + stderr blocks the call).
- **Codex** → merge `codex.toml` into `./.codex/config.toml`. `guard.sh --codex` returns
  `{"hookSpecificOutput":{...,"permissionDecision":"deny"}}`. Verify the `matcher` tool names
  against your codex version.
- **opencode** → copy `opencode.ts` to `./.opencode/plugin/secrets-guard.ts` (throws to block).

`guard.sh` is the shared detector; the per-agent files only wire it in. python3 absent → fail-open.

## Scope / limits
Path- and command-based, with a heuristic on the final pipeline stage. A secret pasted as a literal
value into a tool arg is not caught here — the `secrets` rule + the git-quality-gate staged-secret
scan cover commits.
