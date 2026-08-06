#!/usr/bin/env sh
# install.sh — bring up ~/.agents on a NEW (consumer) machine from the published repo.
#
# Distribution model: PUBLIC repo — READ-ONLY for consumers, edits only on the OWNER machine.
#   - Owner machine   : has ~/.agents with a WRITE remote (SSH git@github-a3); does NOT run this.
#   - Consumer machine: clones ANONYMOUSLY over HTTPS (no key, no login) and only pulls. Write is
#     impossible without owner credentials; a baseline change found here is relayed to the owner to commit.
#
# POSIX sh — runs on Linux / WSL2 / macOS / Git-Bash. Native Windows cmd/PowerShell: see README Setup
# (mklink / New-Item, reversed link/target order, Developer Mode).
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

# 4. Integrity — report what was pulled and verify authenticity (SHA anchor + optional GPG tag).
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
if [ -n "$TAG" ]; then
  echo "   latest snapshot: $TAG -> $(git -C "$DEST" rev-parse --short "$TAG^{commit}")"
  if git -C "$DEST" verify-tag "$TAG" >/dev/null 2>&1; then
    echo "   signature: GPG-VALID (verified against the owner's public key)"
  else
    echo "   signature: unsigned/unverifiable — trust anchor is the commit SHA over HTTPS/TLS."
    echo "              for signature-level trust: owner signs tags (git tag -s), consumer imports the owner's GPG key."
  fi
fi

echo "== done. ~/.agents is read-only here; edits happen on the owner machine. =="
