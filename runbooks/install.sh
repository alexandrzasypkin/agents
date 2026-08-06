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
# Usage:   sh install.sh                                # default: anonymous HTTPS clone, zero setup
#          AGENTS_REPO=<url> sh install.sh              # override the clone URL if needed
#          sh install.sh --install-baseline-guard       # ALSO install the global baseline-guard (opt-in)
#          curl -fsSL <raw>/install.sh | sh -s -- --install-baseline-guard   # same, one-shot
set -eu

REPO_URL="${AGENTS_REPO:-https://github.com/alexandrzasypkin/agents.git}"
DEST="$HOME/.agents"

INSTALL_GUARD=0
for arg in "$@"; do
  case "$arg" in
    --install-baseline-guard) INSTALL_GUARD=1 ;;
    *) echo "unknown arg: $arg" >&2 ;;
  esac
done

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
#    Auto-install ONLY with --install-baseline-guard (idempotent, per present agent); else guide.
GUARD_DIR="$DEST/hooks/baseline-guard"
install_guard() {
  # codex — append the TOML section (safe: array-of-tables at EOF, disturbs nothing above)
  if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    cfg="$HOME/.codex/config.toml"
    if [ -f "$cfg" ] && grep -q baseline-guard "$cfg"; then echo "   codex: already present — skipped"
    else mkdir -p "$HOME/.codex"; { echo; cat "$GUARD_DIR/codex.toml"; } >> "$cfg"; echo "   codex: appended -> $cfg"; fi
  fi
  # claude — JSON merge via python3; missing file = write verbatim; malformed = leave it, guide
  if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    cfg="$HOME/.claude/settings.json"
    if [ -f "$cfg" ] && grep -q baseline-guard "$cfg"; then echo "   claude: already present — skipped"
    elif command -v python3 >/dev/null 2>&1; then
      python3 - "$cfg" "$GUARD_DIR/claude.json" <<'PY'
import json, sys, os
cfg_path, frag_path = sys.argv[1], sys.argv[2]
with open(frag_path) as f: frag = json.load(f)
cfg = {}
if os.path.exists(cfg_path):
    try:
        with open(cfg_path) as f: cfg = json.load(f)
    except Exception:
        print("   claude: settings.json is not valid JSON — NOT modified; merge by hand"); sys.exit(0)
cfg.setdefault("hooks", {}).setdefault("PreToolUse", []).extend(frag["hooks"]["PreToolUse"])
os.makedirs(os.path.dirname(cfg_path) or ".", exist_ok=True)
with open(cfg_path, "w") as f: json.dump(cfg, f, indent=2)
print("   claude: merged ->", cfg_path)
PY
    else echo "   claude: python3 missing — merge $GUARD_DIR/claude.json by hand"; fi
  fi
  # opencode — copy the plugin file (safe: standalone .ts, no merge)
  if command -v opencode >/dev/null 2>&1 || [ -d "$HOME/.config/opencode" ]; then
    pdir="$HOME/.config/opencode/plugin"; mkdir -p "$pdir"
    cp "$GUARD_DIR/opencode.ts" "$pdir/baseline-guard.ts"; echo "   opencode: plugin -> $pdir/baseline-guard.ts"
  fi
}
if [ "$INSTALL_GUARD" = 1 ]; then
  echo "== installing baseline-guard (--install-baseline-guard) =="
  install_guard
elif grep -rq "baseline-guard" "$HOME/.claude/settings.json" "$HOME/.codex/config.toml" 2>/dev/null; then
  echo "== baseline-guard: already present in a global agent config =="
else
  echo "== baseline-guard NOT installed — the guardrail that makes writes to ~/.agents need your approval =="
  echo "   auto-install: re-run with  --install-baseline-guard   (one-shot: curl -fsSL <raw>/install.sh | sh -s -- --install-baseline-guard)"
  echo "   by hand: merge $GUARD_DIR/{claude.json,codex.toml} into ~/.claude/settings.json · ~/.codex/config.toml; copy opencode.ts -> ~/.config/opencode/plugin/ (README > Setup)"
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
