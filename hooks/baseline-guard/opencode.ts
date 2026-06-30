// baseline-guard for opencode. Install GLOBALLY into ~/.config/opencode/plugin/baseline-guard.ts
// opencode plugins cannot return a native "ask", so a write to ~/.agents is hard-blocked here.
// To edit the baseline from opencode, disable this plugin for that session.
import type { Plugin } from "@opencode-ai/plugin"
import * as os from "node:os"
import * as path from "node:path"

const LIB = path.resolve(os.homedir(), ".agents")

function underLib(p: string): boolean {
  const abs = path.resolve(p.replace(/^~(?=\/)/, os.homedir()))
  return abs === LIB || abs.startsWith(LIB + path.sep)
}

export const BaselineGuard: Plugin = async () => ({
  "tool.execute.before": async (input, output) => {
    if (!["edit", "write"].includes(input.tool)) return
    const a = (output && (output as { args?: Record<string, unknown> }).args) || {}
    const p = (a.filePath || a.path) as string | undefined
    if (typeof p === "string" && underLib(p)) {
      throw new Error("baseline-guard: writing to ~/.agents needs explicit approval. Reading is free.")
    }
  },
})
