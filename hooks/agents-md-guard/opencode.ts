// opencode agents-md-guard plugin. Install into ./.opencode/plugin/agents-md-guard.ts
// Mirrors hooks/agents-md-guard/lessons-cap.sh: cap the AGENTS.md lessons block (in markers), block
// only an edit that ADDS a bullet while over the cap. No markers -> inert. opencode blocks by throwing.
import type { Plugin } from "@opencode-ai/plugin"
import { readFileSync } from "node:fs"
import { basename } from "node:path"

const START = /<!--\s*lessons:start(?:\s+max=(\d+))?\s*-->/i
const END = /<!--\s*lessons:end\s*-->/i

function block(text: string): [number, number] | null {
  const m = START.exec(text)
  if (!m) return null
  const rest = text.slice(m.index + m[0].length)
  const e = END.exec(rest)
  if (!e) return null
  const seg = rest.slice(0, e.index)
  const n = (seg.match(/^-\s/gm) || []).length
  return [n, m[1] ? parseInt(m[1], 10) : 12]
}

export const AgentsMdGuard: Plugin = async () => ({
  "tool.execute.before": async (_input, output) => {
    const a = (output && (output as { args?: Record<string, unknown> }).args) || {}
    const str = (k: string) => (typeof a[k] === "string" ? (a[k] as string) : "")
    const fp = str("filePath") || str("path") || str("file_path")
    if (!fp || basename(fp) !== "AGENTS.md") return

    let before = ""
    try { before = readFileSync(fp, "utf8") } catch { before = "" }

    let after: string
    if (typeof a.content === "string") after = a.content as string
    else {
      const old = str("old_string") || str("oldString")
      const nw = str("new_string") || str("newString")
      if (!old) return
      after = a.replace_all || a.replaceAll ? before.split(old).join(nw) : before.replace(old, nw)
    }

    const bi = block(after)
    if (!bi) return
    const [afterN, mx] = bi
    const beforeN = block(before)?.[0] ?? 0
    if (afterN > mx && afterN > beforeN)
      throw new Error(
        `agents-md-guard: the AGENTS.md lessons block is capped at max=${mx} bullets ` +
          `(this edit takes it ${beforeN}->${afterN}). The anchor is a POINTER — merge/drop a line ` +
          `whose home is a rule/REGISTRY/docs, or raise max= on the marker with a REGISTRY note.`,
      )
  },
})
