# cf-prod-guard (hook)

PreToolUse `Bash` guard: pauses **mutating production Cloudflare operations** for the user's approval
(`permissionDecision: "ask"`, not a hard `exit 2` — a hard block leaves no door). Gates:

- `wrangler pages deploy`
- `wrangler d1 migrations apply … --remote`
- `wrangler d1 execute … --remote` **only when it writes** (SQL `INSERT/UPDATE/DELETE/DROP/ALTER/CREATE/REPLACE/TRUNCATE` or `--file`)
- `wrangler pages secret put|delete`

## Two things it deliberately does NOT do
- **Read-only prod is not gated.** `d1 execute --remote "SELECT …"` and `migrations list --remote` pass
  untouched — otherwise routine prod inspection prompts on every query.
- **It cannot remember approval.** A hook fires on EVERY matching call; there is no persistence (unlike
  the `permissions.allow` list). That is why it gates only genuine mutations (rare, consequential) — so
  the residual prompts are few and appropriate. A mutation loop (backfill) will still prompt per op; run
  those via the user's own shell (`!`) or the standard permission list if that friction is unwanted.

The routine prod path is CI (push → the project's deploy workflow); this guard is the safety net for the
occasional direct prod op. Attached via the `cf-wrangler` rule.

## Per-agent install
- **Claude** → merge `claude.json` into `./.claude/settings.json` (`hooks.PreToolUse`, matcher `Bash`).
- **Codex** → merge `codex.toml` into `./.codex/config.toml`. If your codex version honours only
  `"deny"`, the `"ask"` this guard returns is ignored and it degrades to advisory — verify per version.
- **opencode** → copy `opencode.ts` to `./.opencode/plugin/cf-prod-guard.ts`. The opencode plugin API
  can only block by throwing (no "ask"), and this guard is an approval prompt by design — so there it
  is **advisory** (warns, does not block).

`guard.sh` is the shared detector; the per-agent files only wire it in.
