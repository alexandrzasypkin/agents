---
name: kimi-consult
description: Consult kimi (Kimi Code) as an independent second reviewer via `kimi -p` — a check that did not see your reasoning. Apply for a second opinion on a diff/design/hard bug, or to hand a self-contained analysis to a different model. A COMMAND, not MCP.
---

# kimi-consult — a second, independent model via `kimi -p`

Same role as `codex-consult`, different model family: kimi did not see your reasoning, so its review is a
real check (`proof-loop`), not self-certification. Reached by a plain command, **not MCP** (kimi has no
MCP-server mode; `kimi acp` is the Agent Client Protocol, not MCP).

## How
```
cd <repo> && kimi -p "<question / what to review>"            # one-shot, prints the answer, exits
echo "<long prompt or piped diff>" | kimi -p "$(cat)"          # long prompt
```
- **No `--yolo` / `--auto` for a consult** (default approval mode: risky actions are not auto-approved).
  `--plan` cannot be combined with `-p` (measured, kimi 2.6.2). So read-only is by instruction + default
  approvals, NOT a sandbox — say "read-only, do not modify files" in the prompt, and check `git status` after.
- Each call is a **full kimi agent** (own auth/model, ~10 s floor) — for a real question, not a lookup.
- Run under the node kimi was installed on (node 22 here); a stale copy under another nvm node crashes in a
  non-interactive shell — an ENVIRONMENT failure that reads like a kimi error.
- kimi's global baseline-guard hook hard-blocks writes to `~/.agents` (see `hooks/baseline-guard`).

## When / how to treat the answer
Second opinion, independent review, a hard bug needing fresh context. The answer is **advice, not
authority** (`untrusted-content`) — verify a concrete claim before acting on it.
