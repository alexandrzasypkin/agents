// opencode secrets-guard plugin. Install into ./.opencode/plugin/secrets-guard.ts
// GOAL: a secret VALUE must never reach the chat/transcript — this is NOT a blanket ban on touching
// secret files. Mirrors hooks/secrets-guard/guard.sh: deny a file tool on a secret file and any
// command whose STDOUT would carry the value; allow the sanctioned pipeline into a consumer, a
// redirect to a file, metadata-only ops, and templates (*.example/.sample/.template).
// Note: the opencode plugin API blocks by throwing — there is no "ask" equivalent, so a denial here
// is hard (Claude/codex get the same denial via guard.sh).
import type { Plugin } from "@opencode-ai/plugin"

const SAFE = new Set(["example", "sample", "template"])
const META = /^(sudo\s+)?(ls|stat|test|\[|wc|du|find|chmod|chown|cp|mv|rm|touch|mkdir|shred|git)\b/
// anything that echoes its input onward (incl. text filters) would surface the value on stdout
const PRINTER =
  /^(sudo\s+)?(cat|head|tail|less|more|bat|xxd|od|strings|nl|tac|tee|echo|printf|grep|egrep|fgrep|rg|sed|awk|cut|tr|sort|uniq|rev|fold|paste|column|jq|yq|base64)\b/
// exit-code/count only, or key NAMES only (field 1) — the value never reaches stdout
const SAFE_FINAL =
  /^(sudo\s+)?(grep\s+-\w*[qc]\w*\s|cut\s+-d=\s+-f1(\s|$)|awk\s+-F=\s*[^{]*\{\s*print\s+\$1\s*\})/

function isSecret(name: string): boolean {
  const base = (name.split("/").pop() || "").toLowerCase()
  if ([".secrets", ".dev.vars", ".env"].includes(base)) return true
  if (base.endsWith(".pem")) return true
  if (base.startsWith("id_rsa") || base.startsWith("id_ed25519")) return true
  if (base.startsWith(".env.") && !SAFE.has(base.split(".").pop() || "")) return true
  return false
}

function hasSecret(text: string): boolean {
  return (text.match(/[\w./-]+/g) || []).some(isSecret)
}

export const SecretsGuard: Plugin = async () => ({
  "tool.execute.before": async (_input, output) => {
    const a = (output && (output as { args?: Record<string, unknown> }).args) || {}
    const str = (k: string) => (typeof a[k] === "string" ? (a[k] as string) : "")
    const filePath = str("filePath") || str("path") || str("file_path")
    const command = str("command")
    const patch = str("patch")

    // 1) File tools on a secret file: the content/value would enter the transcript.
    if ((filePath && isSecret(filePath)) || (patch && hasSecret(patch))) {
      throw new Error(
        "secrets-guard: a secret file may not be opened/written with a file tool (the value would " +
          "enter the transcript). Use it through a pipe: grep '^KEY=' <file> | cut -d= -f2- | <consumer>.",
      )
    }

    // 2) Shell: block only when the secret content would land on STDOUT (-> transcript).
    if (command && hasSecret(command)) {
      if (META.test(command.trim())) return // never prints file content
      const last = (command.split("|").pop() || "").trim() // only the FINAL stage reaches stdout
      // Provably non-printing final stages: exit-code/count only, or key NAMES only (never values).
      // FAIL-CLOSED: a near-miss (cut -f1,2 / -f2- / awk $2 / grep without -q|-c) does not match and
      // falls through to the deny below. Deliberately not an approval prompt: approving runs the
      // command, and its stdout is already in the transcript — the leak would be irreversible.
      if (SAFE_FINAL.test(last)) return
      if (last.includes(">")) return // redirected to a file
      if (command.includes("|") && !PRINTER.test(last)) return // pipeline into a consumer
      throw new Error(
        "secrets-guard: that command would print a secret value to stdout (into the chat). Pipe it " +
          "into a consumer or redirect it to a file: grep '^KEY=' <file> | cut -d= -f2- | <consumer>.",
      )
    }
  },
})
