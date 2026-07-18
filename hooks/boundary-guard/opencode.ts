// opencode boundary-guard plugin. Install into ./.opencode/plugin/boundary-guard.ts
// PLATFORM LIMIT: the opencode plugin API can only BLOCK (throw) — there is no "ask"/approval
// equivalent. This guard is deliberately an approval prompt, not a wall, so here it is ADVISORY:
// it warns and lets the write through. Claude gets the real prompt via guard.sh.
// Reads the project's patterns from .agents/hooks/boundary-guard/patterns.conf (relative to the
// project root): one `<ERE path pattern><TAB><reason>` per line. No conf -> no-op.
import { readFileSync } from "node:fs"
import type { Plugin } from "@opencode-ai/plugin"

const CONF = ".agents/hooks/boundary-guard/patterns.conf"

function loadPatterns(): Array<[RegExp, string]> {
  try {
    return readFileSync(CONF, "utf8")
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l && !l.startsWith("#"))
      .map((l) => {
        const [pat, ...rest] = l.split("\t")
        return [new RegExp(pat), rest.join("\t").trim() || "boundary-sensitive path"] as [RegExp, string]
      })
  } catch {
    return []
  }
}

export const BoundaryGuard: Plugin = async () => ({
  "tool.execute.before": async (_input, output) => {
    const a = (output && (output as { args?: Record<string, unknown> }).args) || {}
    const fp =
      (typeof a.filePath === "string" && a.filePath) ||
      (typeof a.path === "string" && a.path) ||
      (typeof a.file_path === "string" && a.file_path) ||
      ""
    if (!fp) return
    for (const [re, reason] of loadPatterns()) {
      if (re.test(fp)) {
        console.warn(`[boundary-guard] ${reason} — confirm this write is intended. (advisory: opencode cannot prompt)`)
        return
      }
    }
  },
})
