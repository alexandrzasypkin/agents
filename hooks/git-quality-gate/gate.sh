#!/usr/bin/env bash
# git-quality-gate — run the project's quality checks by language.
# Usage: gate.sh <commit|push>
#   commit -> fast: secret scan (staged) + linters
#   push   -> full: linters + type-check + build + tests
# Exit 2 blocks the git operation. A missing tool is reported, not fatal
# (install-when-needed is a project decision; see the env-setup rule).

set -uo pipefail
[ -n "${AGENTS_DEBUG:-}" ] && set -x   # opt-in trace: AGENTS_DEBUG=1
mode="${1:-commit}"
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

fail=0
have()    { command -v "$1" >/dev/null 2>&1; }
miss()    { printf 'git-quality-gate: %s not found - skipped (install per env-setup)\n' "$1" >&2; }
run()     { echo "+ $*" >&2; "$@" || fail=1; }
# like run(), but pytest exit 5 = "no tests were collected" — not a failure (e.g. after excluding a marker).
run_tests(){ echo "+ $*" >&2; "$@"; local rc=$?; [ "$rc" -eq 0 ] || [ "$rc" -eq 5 ] || fail=1; }
# Files IN SCOPE: check the CHANGE, not the repo. commit = staged (light gate). push = the range not
# yet on the branch's upstream (@{u}..HEAD) — a doc-only push must not re-run lint/tsc/build/tests over
# unchanged code. tsc/build/tests are whole-tree BY NATURE, so any code file in the range still triggers
# the FULL gate; scoping only skips a code-free push, which cannot break code. No upstream (or gate.sh
# run by hand) -> whole tree, never a silent skip.
#
# [!] Do NOT read the pre-push stdin (the ref list git feeds the hook) to compute an exact per-ref
# range: consuming a pre-push hook's stdin breaks the real `git push` on some transports (ssh) — the
# push dies with SIGPIPE (141) and sends nothing while the gate still prints "ok" (a silent no-push).
# The upstream range is robust and transport-independent. Cost: a push of a non-current branch or an
# explicit refspec is scoped by the CURRENT branch's upstream — conservative (an extra full gate, never
# a skip). Incident: 301 (2026-08-25), reproduced two-sided on a real ssh repo.
push_range=""
if [ "$mode" = push ]; then
  # Scope = what this push changes vs what the TARGET REMOTE already has. git passes the pre-push hook
  # the pushed remote's NAME as argv[1] — here $2, after the `push` mode arg (the pre-push wrapper
  # forwards "$@"). Use it: a multi-remote repo pushes to a remote that is NOT the current branch's
  # @{u}, and scoping by @{u} then drags a stale unrelated remote's history and FALSE-BLOCKS. argv is
  # SAFE to read — the stdin ban (incident 301: consuming the pre-push ref list breaks ssh-push with
  # SIGPIPE) is ONLY about STDIN, never argv.
  #   base = refs/remotes/<remote>/<current-branch> if it resolves to a real commit OBJECT; else @{u};
  #   else the whole tree. `cat-file -e` (not rev-parse --verify, which accepts any well-formed sha)
  #   guards a dangling/pruned base, so a missing object falls to the whole tree, never a silent skip.
  # Residual: an explicit refspec-rename (`git push <remote> local:other`) is scoped by the CURRENT
  # branch's tracking ref, not `other` — argv does not carry the receiving ref (only stdin does, which
  # we must not read). That can mis-scope; it degrades to "caught by the next normal push", not a
  # permanent miss. Incidents: 301 (stdin/ssh, 2026-08-25), booking (dangling base 2026-08-25;
  # multi-remote base 2026-08-27).
  remote="${2:-}"; branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"; base=""
  if [ -n "$remote" ] && [ -n "$branch" ] \
     && git cat-file -e "refs/remotes/$remote/$branch^{commit}" 2>/dev/null; then
    base="refs/remotes/$remote/$branch"
  else
    ubase="$(git rev-parse -q --verify '@{u}' 2>/dev/null)"
    [ -n "$ubase" ] && git cat-file -e "$ubase^{commit}" 2>/dev/null && base="$ubase"
  fi
  # A remote with SEVERAL push URLs (`remote.<name>.pushurl` twice — a mirror) runs this hook ONCE PER
  # URL, and git moves the tracking ref as soon as the FIRST URL succeeds — so a LATER invocation
  # computes base == HEAD, an EMPTY range, every scoped() false, and the gate prints "ok" having checked
  # NOTHING (the "failure looks like success" class again). So RECORD the first invocation's scope (keyed
  # by HEAD, one line in $GIT_DIR, never committed) and REUSE it for the sibling URLs; with no usable
  # record an empty range falls through to the whole tree, never a skip. Keyed by HEAD, a stale record
  # can only WIDEN the range (extra checks), never narrow it. Incident: 301 (2026-08-31, github +
  # self-hosted mirror). Verified via a real two-URL push.
  head_sha="$(git rev-parse HEAD 2>/dev/null)"
  memo="$(git rev-parse --git-dir)/git-quality-gate.push-scope"
  base_sha=""; [ -n "$base" ] && base_sha="$(git rev-parse -q --verify "$base" 2>/dev/null)"
  if [ -n "$base_sha" ] && [ "$base_sha" != "$head_sha" ]; then
    push_range="$base_sha..HEAD"
    printf '%s %s\n' "$head_sha" "$base_sha" >"$memo" 2>/dev/null || true
  elif [ -n "$base_sha" ]; then                       # base collapsed to HEAD: a later URL of the same push
    m_head=""; m_base=""
    [ -r "$memo" ] && read -r m_head m_base <"$memo"
    if [ "$m_head" = "$head_sha" ] && [ -n "$m_base" ] && git cat-file -e "$m_base^{commit}" 2>/dev/null; then
      push_range="$m_base..HEAD"
      echo "git-quality-gate: same push, another URL of '$remote' - re-checking $m_base..HEAD" >&2
    fi                                                # no usable record -> range stays empty -> whole tree
  fi
fi

in_scope() {
  if   [ "$mode" = commit ]; then git diff --cached --name-only --diff-filter=ACM -- "$@"
  elif [ -n "$push_range" ]; then git diff --name-only --diff-filter=ACM "$push_range" -- "$@"
  else git ls-files -- "$@"; fi
}
scoped()  { in_scope "$@" | grep -q .; }

# --- secret scan (commit) — BUILT-IN grep, UNCONDITIONAL. NEVER skip-if-missing:
#     secrets are base/[CRITICAL]. External scanners only ADD to this, never replace it. ---
if [ "$mode" = commit ]; then
  staged="$(git diff --cached --name-only --diff-filter=ACM)"
  # secret files staged (templates .example/.sample/.template are allowed)
  if printf '%s\n' "$staged" | grep -iE '(^|/)(\.env(\..+)?|\.dev\.vars|\.secrets)$' \
       | grep -ivqE '\.(example|sample|template)$'; then
    echo "git-quality-gate: BLOCK - a secret file is staged (.env/.dev.vars/.secrets)" >&2; fail=1
  fi
  # private key material in staged content
  if git diff --cached -U0 --diff-filter=ACM | grep -qE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
    echo "git-quality-gate: BLOCK - private key material is staged" >&2; fail=1
  fi
  # optional deeper scanner ADDS to the built-in (never the sole mechanism)
  if have gitleaks; then
    gitleaks protect --staged >/dev/null 2>&1 || { echo "git-quality-gate: gitleaks flagged staged content" >&2; fail=1; }
  fi
fi

# --- Python ---
if scoped '*.py' 'pyproject.toml'; then
  if have ruff; then
    if [ "$mode" = commit ]; then
      mapfile -t _pyf < <(in_scope '*.py')                     # light gate: lint STAGED .py only
      if [ "${#_pyf[@]}" -gt 0 ]; then run ruff check -- "${_pyf[@]}"; else run ruff check .; fi
    else run ruff check .; fi                                  # push: whole tree (full gate)
  else miss ruff; fi
  if [ "$mode" = push ]; then
    if have pyright; then run pyright; else miss pyright; fi
    if have pytest; then run_tests pytest -q
    elif have python3 && python3 -c 'import pytest' 2>/dev/null; then run_tests python3 -m pytest -q
    else miss pytest; fi
  fi
fi

# --- JS/TS ---
if [ -f package.json ] && scoped '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.cjs' '*.astro' '*.vue' 'package.json' 'tsconfig*.json'; then
  if grep -q '"lint"' package.json; then run npm run -s lint
  elif npx --no-install eslint --version >/dev/null 2>&1; then run npx --no-install eslint .
  else miss eslint; fi
  if [ "$mode" = push ]; then
    # REAL tsc — NOT the project's "typecheck" npm script: a mislabeled script (e.g. `wrangler types`,
    # a codegen) exits 0 without checking a single type (see quality-js [CRITICAL]). Needs a real
    # tsconfig.json. --incremental caches to .tsbuildinfo (gitignore it) → first run slow, then seconds.
    if [ ! -f tsconfig.json ]; then printf 'git-quality-gate: no tsconfig.json - tsc skipped (content/JS repo)\n' >&2
    elif npx --no-install tsc --version >/dev/null 2>&1; then run npx --no-install tsc --noEmit --incremental
    else miss tsc; fi
    grep -q '"build"' package.json && run npm run -s build   # compile check (bundler / wrangler)
    grep -q '"test"' package.json && run npm test --silent
  fi
fi

# --- Bash ---
if scoped '*.sh'; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    run bash -n "$f"
    if have shellcheck; then run shellcheck "$f"; fi
  done < <(in_scope '*.sh')
fi

# --- Perl ---
if scoped '*.pl' '*.pm'; then
  while IFS= read -r f; do [ -f "$f" ] || continue; run perl -c "$f"; done < <(in_scope '*.pl' '*.pm')
fi

# --- C++ (light syntax check) ---
if scoped '*.cpp' '*.cc' '*.cxx'; then
  if have g++; then
    while IFS= read -r f; do [ -f "$f" ] || continue; run g++ -fsyntax-only -std=c++17 "$f"; done < <(in_scope '*.cpp' '*.cc' '*.cxx')
  else miss g++; fi
fi

if [ "$fail" -ne 0 ]; then
  echo "git-quality-gate ($mode): FAILED - fix the above (use --no-verify only with an explicit reason)" >&2
  exit 2
fi
echo "git-quality-gate ($mode): ok" >&2
exit 0
