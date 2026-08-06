#!/usr/bin/env sh
# install.sh — bring up ~/.agents on a NEW (consumer) machine from the published repo.
#
# Distribution model: PUBLIC repo — READ-ONLY for consumers, edits only on the OWNER machine.
#   - Owner machine   : has ~/.agents with a WRITE remote (SSH git@github-a3); does NOT run this.
#   - Consumer machine: clones ANONYMOUSLY over HTTPS (no key, no login) and only pulls. Write is
#     impossible without owner credentials; a baseline change found here is relayed to the owner to commit.
#
# POSIX sh — runs on Linux / WSL2 / macOS / Git-Bash. Native Windows cmd/PowerShell: use the
# PowerShell counterpart runbooks/install.ps1 (same steps, native symlinks) instead of this script.
#
# Usage:   sh install.sh                       # default: anonymous HTTPS clone, zero setup
#          AGENTS_REPO=<url> sh install.sh     # override the clone URL if needed
set -eu

REPO_URL="${AGENTS_REPO:-https://github.com/alexandrzasypkin/agents.git}"
DEST="$HOME/.agents"

# 1. Clone read-only (skip if already present — never clobber an existing checkout).
if [ -e "$DEST/.git" ]; then
  echo "== ~/.agents already a git repo — pulling latest (read-only) =="
  git -C "$DEST" pull --ff-only
else
  echo "== cloning $REPO_URL -> $DEST =="
  git clone "$REPO_URL" "$DEST"
fi

# 2. Global symlinks — ONLY for agents actually present on this host (not all 3 need be installed).
#    Claude reads ~/.claude/CLAUDE.md, Codex reads ~/.codex/AGENTS.md; opencode reads ~/.agents
#    natively (no symlink). An agent counts as present if its CLI is in PATH or its config dir exists.
link_agent() {  # name  cli  dir  link
  if command -v "$2" >/dev/null 2>&1 || [ -d "$3" ]; then
    mkdir -p "$3"
    ln -sfn "$DEST/AGENTS.md" "$4"                    # ln -sfn is idempotent
    echo "== $1: linked $4 -> ~/.agents/AGENTS.md =="
  else
    echo "== $1: not detected — skipped =="
  fi
}
link_agent claude claude "$HOME/.claude" "$HOME/.claude/CLAUDE.md"
link_agent codex  codex  "$HOME/.codex"  "$HOME/.codex/AGENTS.md"
command -v opencode >/dev/null 2>&1 && echo "== opencode: detected — reads ~/.agents natively, no symlink =="

# 3. baseline-guard — the ONE global guardrail bootstrap never writes (README Guardrails).
#    Merging into a global JSON/TOML config is risky to automate → guide, do not clobber.
if grep -rq "baseline-guard" "$HOME/.claude/settings.json" "$HOME/.codex/config.toml" 2>/dev/null; then
  echo "== baseline-guard: already present in a global agent config =="
else
  echo "== ACTION: install baseline-guard into each agent's GLOBAL config (by hand, once) =="
  echo "   Fragments: $DEST/hooks/baseline-guard/{claude.json,codex.toml,opencode.ts}"
  echo "   Targets:   ~/.claude/settings.json · ~/.codex/config.toml · ~/.config/opencode/plugin/"
  echo "   It makes every write to ~/.agents need explicit approval (protects the shared baseline)."
fi

# 4. Integrity — report what was pulled. Trust anchor = commit SHA over HTTPS/TLS (SHA-only model).
#    No hardcoded "expected SHA" (it moves every commit); the checks are dynamic.
echo "== integrity =="
echo "   HEAD: $(git -C "$DEST" rev-parse HEAD)"
if [ -n "$(git -C "$DEST" status --porcelain)" ]; then
  echo "   WARNING: working tree is DIRTY — a read-only consumer must be clean (local edits = tampering/drift)."
fi
if ! git -C "$DEST" merge-base --is-ancestor "@{u}" HEAD 2>/dev/null && \
   ! git -C "$DEST" diff --quiet HEAD "@{u}" 2>/dev/null; then
  echo "   note: HEAD differs from origin — run 'git -C ~/.agents pull --ff-only' to reconcile."
fi
TAG=$(git -C "$DEST" describe --tags --abbrev=0 --match 'snapshot-*' 2>/dev/null || true)
[ -n "$TAG" ] && echo "   latest snapshot: $TAG -> $(git -C "$DEST" rev-parse --short "$TAG^{commit}")"
echo "   trust anchor: commit SHA over HTTPS/TLS (SHA-only model; tags are not GPG-signed)."

echo "== done. ~/.agents is read-only here; edits happen on the owner machine. =="
