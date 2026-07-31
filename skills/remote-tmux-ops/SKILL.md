---
name: remote-tmux-ops
description: Drive remote tmux sessions over SSH safely — discover panes, capture output, send commands. Apply when inspecting or operating long-running processes on a remote host via tmux.
---

# remote-tmux-ops

Remote work inside tmux on a project server. Always go local machine -> `ssh <host>` ->
`tmux`. `<host>` is a `~/.ssh/config` alias (below); pane layouts are project-specific — read the
project's docs; do not hardcode hosts or panes here.

## Connection — `~/.ssh/config` alias
Address every remote host by a **`~/.ssh/config` alias** (`ssh <host>`), never a raw
`user@ip -p <port> -i <key>` on the command line — the alias keeps IPs, ports, and key paths out of
shell history and tmux scrollback (secrets hygiene) and gives one stable name.
- Resolve/verify: `ssh -G <host>` (dumps the effective config); smoke-test `ssh <host> true` before driving tmux.
- **Missing alias, or no config file → create it.** Ensure `~/.ssh` first
  (`mkdir -p ~/.ssh && chmod 700 ~/.ssh`), then append a block and `chmod 600 ~/.ssh/config`:
  ```
  Host <alias>
      HostName <ip-or-dns>
      User <user>
      Port <port>
      IdentityFile ~/.ssh/<key>
      IdentitiesOnly yes
  ```
  `IdentitiesOnly yes` = offer only the named key, not every key in the agent — avoids the server's
  `MaxAuthTries` cutting you off with "Too many authentication failures". (Do **not** add
  `IdentityAgent none` by default — it disables the agent, so a passphrased key is re-prompted on
  every `ssh` call, which this skill makes many of; reserve it for hardened "on-disk key only" hosts.)
  Take the connection details from the project docs / the user — don't invent them. Record the
  **alias** in the project (`AGENTS.md` / `REGISTRY.md`); the config and the private key stay in
  `~/.ssh/` (machine-level, never committed — the key is a secret).

## Rules
- Never run local `tmux` for server operations — always through SSH: `ssh <host> "tmux ..."`.
- Read-only first (`ls`, `lsw`, `capture-pane`); confirm the target pane exists before `send-keys`.
- Do not assume identical layouts across hosts. Address panes as `session:window.pane`.

## Discovery (before acting)
```bash
ssh <host> "tmux ls"
ssh <host> "tmux lsw -a"
ssh <host> "tmux lsp -a -F '#S:#W.#P #{pane_current_command}'"
```
Map the required pane, then capture or send.

## Common commands
```bash
# capture a pane (read-only)
ssh <host> "tmux capture-pane -t <session>:<window>.<pane> -p" | tail -20
# send a shell command
ssh <host> "tmux send-keys -t <session>:<window>.<pane> '<command>' C-m"
# clear a pending input line first
ssh <host> "tmux send-keys -t <session>:<window>.<pane> C-u"
```

## send-keys rules
- **`C-m` is the default submit for everything — shells AND interactive TUIs.** The two keys coincide
  only while the terminal is in normal mode. A TUI in **application keypad mode** (DECKPAM) makes
  `Enter` send `\eOM` (SS3 M), not `\r`, and `send-keys Enter` honours that mode → the app gets an
  escape sequence it does not count as submit. `C-m` is the literal CR (`\r`), unaffected by the mode.
  Observed: a TUI where `Enter` did nothing and `C-m` submitted.
- **Submit = C-m, then VERIFY, then fall back to `Enter`.** A clean `send-keys` exit 0 only means the
  pane exists — it says nothing about whether the key was accepted. So for every submit:
  1. `send-keys … C-m`.
  2. `capture-pane` and check a **concrete** submit signal — NOT "something changed": the **input line
     emptied** (the text left the box) and/or the message **appears in the transcript/output** above,
     or the app went **busy / answering**.
  3. If the text is **still sitting in the input line** → send `Enter` once, then `capture-pane` again.
     (One of `C-m`=`\r` / `Enter`=`\eOM` is the other's fallback, per the keypad mode above.)
  Never report a remote submit as done on the `send-keys` exit code alone.
- Before sending into a reused pane: send `C-u`, then `capture-pane` to confirm the prompt state.
- Single-quote the payload only when it contains no single quotes. If it contains quotes,
  `$`, backticks, regex/sed, JSON, or substitutions — avoid inline quoting: put it in a
  script/file, or run it directly via `ssh <host> '<command>'` when tmux interaction isn't needed.

[CRITICAL] Never send secrets via `send-keys` — tmux scrollback is persistent; treat any
pasted secret as exposed. (See the `secrets` rule.)

## Safety
- For restarts or config-changing commands, show the exact target pane and command before running.
- Prefer `capture-pane` over attaching interactively. If output is ambiguous, recapture with
  pane metadata before acting.
