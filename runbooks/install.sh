#!/usr/bin/env sh
# install.sh — bring up ~/.agents on a NEW (consumer) machine from the published repo.
#
# Distribution model: READ-ONLY for consumers, edits only on the OWNER machine.
#   - Owner machine   : already has ~/.agents with a WRITE remote; does NOT run this.
#   - Consumer machine: clones read-only (a read-only DEPLOY KEY on the repo) and only pulls.
#     A baseline change discovered here is relayed to the owner machine to commit — never pushed.
#
# POSIX sh — runs on Linux / WSL2 / macOS / Git-Bash. Native Windows cmd/PowerShell: see README Setup
# (mklink / New-Item, reversed link/target order, Developer Mode).
#
# Usage:   AGENTS_REPO=<read-only-clone-url> sh install.sh
#   e.g.   AGENTS_REPO=git@github-a3-ro:alexandrzasypkin/agents.git sh install.sh
#   github-a3-ro = an ~/.ssh/config Host alias whose IdentityFile is the repo's READ-ONLY deploy key.
set -eu

REPO_URL="${AGENTS_REPO:-git@github-a3-ro:alexandrzasypkin/agents.git}"
DEST="$HOME/.agents"

# 1. Clone read-only (skip if already present — never clobber an existing checkout).
if [ -e "$DEST/.git" ]; then
  echo "== ~/.agents already a git repo — pulling latest (read-only) =="
  git -C "$DEST" pull --ff-only
else
  echo "== cloning $REPO_URL -> $DEST =="
  git clone "$REPO_URL" "$DEST"
fi

# 2. Global symlinks so the canon loads every session (README Setup). ln -sfn is idempotent.
mkdir -p "$HOME/.codex" "$HOME/.claude"
ln -sfn "$DEST/AGENTS.md" "$HOME/.codex/AGENTS.md"    # Codex reads AGENTS.md
ln -sfn "$DEST/AGENTS.md" "$HOME/.claude/CLAUDE.md"   # Claude reads CLAUDE.md (no native AGENTS.md)
echo "== symlinks: ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md -> ~/.agents/AGENTS.md =="
# opencode reads ~/.agents natively via each project's opencode.json — no global symlink.

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

echo "== done. ~/.agents is read-only here; edits happen on the owner machine. =="
