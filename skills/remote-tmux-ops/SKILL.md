---
name: remote-tmux-ops
description: Drive remote tmux sessions over SSH safely — discover panes, capture output, send commands. Apply when inspecting or operating long-running processes on a remote host via tmux.
---

# remote-tmux-ops

Remote work inside tmux on a project server. Always go local machine -> `ssh <host>` ->
`tmux`. Host names and pane layouts are project-specific — read the project's docs; do not
hardcode them here.

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
- `C-m` for normal shell command submission; `Enter` for interactive TUI prompts/menus
  (some TUIs read `C-m` as a literal newline).
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
