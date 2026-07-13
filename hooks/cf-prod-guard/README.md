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
