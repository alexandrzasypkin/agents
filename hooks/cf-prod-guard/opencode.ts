// opencode cf-prod-guard plugin. Install into ./.opencode/plugin/cf-prod-guard.ts
// PLATFORM LIMIT: the opencode plugin API can only BLOCK (throw) — there is no "ask"/approval
// equivalent. This guard is deliberately an approval prompt, not a wall (a hard block leaves the
// agent no door), so here it is ADVISORY: it warns and lets the call through. Claude gets the real
// prompt via guard.sh; codex too where "ask" is honoured.
import type { Plugin } from "@opencode-ai/plugin"

const ALWAYS_MUTATING =
  /wrangler\s+pages\s+deploy|wrangler\s+d1\s+migrations\s+apply.*--remote|wrangler\s+pages\s+secret\s+(put|delete)/
const REMOTE_EXEC = /wrangler\s+d1\s+execute.*--remote/
// a write in the SQL, or applying a file — a read-only SELECT is not gated
const SQL_WRITE = /(^|[^a-z])(insert|update|delete|drop|alter|create|replace|truncate)([^a-z]|$)|--file/i

export const CfProdGuard: Plugin = async () => ({
  "tool.execute.before": async (_input, output) => {
    const a = (output && (output as { args?: Record<string, unknown> }).args) || {}
    const cmd = typeof a.command === "string" ? a.command : ""
    if (!cmd) return
    const mutating = ALWAYS_MUTATING.test(cmd) || (REMOTE_EXEC.test(cmd) && SQL_WRITE.test(cmd))
    if (mutating) {
      console.warn(
        "[cf-prod-guard] MUTATING production Cloudflare op (deploy / d1 --remote write / migrations " +
          "apply --remote / secret put|delete). Confirm this was explicitly requested — the default " +
          "prod path is CI. (advisory: opencode cannot prompt for approval)",
      )
    }
  },
})
