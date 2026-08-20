// opencode no-git-add-all plugin. Install into ./.opencode/plugin/no-git-add-all.ts
// Mirrors hooks/no-git-add-all/guard.sh: force EXPLICIT pathspecs in staging (git-discipline).
// Deny `git add .` / `-A` / `-u` / `:/` / `*` and `git commit -a`; allow explicit paths & `git add -p`.
// opencode blocks by throwing — there is no "ask" (Claude/codex get the same denial via guard.sh).
import type { Plugin } from "@opencode-ai/plugin"

const ALL_TOKENS = new Set([".", ":/", ":", "*", "-A", "--all", "-u", "--update"])
const cluster = (t: string, chars: string) =>
  /^-[^-]/.test(t) && [...chars].some((c) => t.slice(1).includes(c))

export const NoGitAddAll: Plugin = async () => ({
  "tool.execute.before": async (_input, output) => {
    const a = (output && (output as { args?: Record<string, unknown> }).args) || {}
    const command = typeof a.command === "string" ? a.command : ""
    if (!command) return
    for (const seg of command.split(/&&|\|\||;|\||\n/)) {
      const m = /^\s*(?:sudo\s+)?git\s+(add|commit)\b(.*)$/.exec(seg.trim())
      if (!m) continue
      const [, sub, rest] = m
      for (const t of rest.trim().split(/\s+/).filter(Boolean)) {
        if (sub === "add" && (ALL_TOKENS.has(t) || cluster(t, "Au")))
          throw new Error(
            `no-git-add-all: \`git add ${t}\` stages everything dirty — list explicit paths ` +
              `(git add path/a path/b). An unrelated/secret/scratch file must not ride into a commit. See git-discipline.`,
          )
        if (sub === "commit" && (t === "-a" || t === "--all" || cluster(t, "a")))
          throw new Error(
            `no-git-add-all: \`git commit ${t}\` stages every modified tracked file — stage explicit paths first. See git-discipline.`,
          )
      }
    }
  },
})
