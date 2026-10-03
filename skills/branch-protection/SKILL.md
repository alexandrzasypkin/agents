---
name: branch-protection
description: Stand up the REMOTE review guardrail for a shared repo — CODEOWNERS at a recognized path + a protected branch requiring code-owner review, then verify it HOLDS by behaviour. A procedure (the owner confirms; it mutates remote settings), NOT auto-run. Pulled by repo-collaboration.
---

# branch-protection — the remote guardrail for a shared repo

`repo-collaboration` principle 2: a cross-actor invariant is held by a **REMOTE platform guardrail**, not
by discipline or a local hook. This is the setup procedure. It **mutates remote repo settings**
(owner-level, outward, hard to reverse) — **show the commands and confirm with the owner before running;
never auto-apply.**

## 0. Orient — don't assume the platform
- **Platform + CLI:** `git remote -v` → the host; which CLI is authed (`gh auth status` / `glab auth
  status` / `tea`). Pick the native CLI or the REST API; don't assume GitHub.
- **Protected branch:** the integration branch (`main` / `master` / `develop`) — confirm, don't assume `main`.
- **Owners:** real platform identities / teams with write access (fill `templates/CODEOWNERS`).

## 1. Place CODEOWNERS (portable) — via a PR, not a direct push
Copy `templates/CODEOWNERS`, fill real owners, commit to a path the platform recognizes:
- **GitHub** → `.github/CODEOWNERS` (or root / `docs/`)
- **GitLab** → root `CODEOWNERS` or `.gitlab/CODEOWNERS`
- **Gitea** → root `CODEOWNERS` or `.gitea/CODEOWNERS`
- **Bitbucket** → no CODEOWNERS; use its *Default reviewers* + merge checks instead.

## 2. Require code-owner review on the protected branch (platform-specific)
The file is **inert** until the platform *requires* owner review on the protected branch. Verify each flag
form against your CLI/API version before running — these are the right endpoints, not guaranteed syntax.

**GitHub** — classic branch protection (or an equivalent ruleset):
```bash
gh api -X PUT "repos/{owner}/{repo}/branches/{branch}/protection" --input - <<'JSON'
{ "required_pull_request_reviews": { "require_code_owner_reviews": true,
    "required_approving_review_count": 1 },
  "enforce_admins": true, "required_status_checks": null, "restrictions": null }
JSON
```
`enforce_admins: true` so the rule binds owners too — otherwise admins silently bypass it.

**GitLab** — protected branch with code-owner approval (+ an MR approval rule):
```bash
glab api -X POST "projects/:id/protected_branches" \
  -f "name={branch}" -f "code_owner_approval_required=true"   # :id = numeric id or URL-encoded path
```

**Gitea / Bitbucket / other** — use that platform's protected-branch + "require review from code owners"
(Gitea) / Default-reviewers + merge checks (Bitbucket) equivalent. **Confirm the exact flag in that
platform's CURRENT API docs — do not guess it.**

## 3. Verify it HOLDS — by BEHAVIOUR, not by the setting
A setting that *reads* "on" is not proof (an admin bypass, a misread flag, a branch that was never actually
protected — failure-looks-like-success). Confirm BOTH:
- re-fetch the protection (`gh api .../protection`, `glab api .../protected_branches`); and
- **behaviourally:** open a trivial PR/MR touching an owned path with NO owner review — it must be
  **blocked from merge**. If it merges, the guardrail does not hold.

## Escalation — pair it with the block
Required review can **deadlock** (a PR left waiting). Agree a wait + an escalation path
(ping / split / arbitrate) — see `repo-collaboration`, "review starvation". Never bypass the guard to beat
the wait.
