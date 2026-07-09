---
name: deploy-models
description: Deployment model selection. Apply when deploying a project.
---

# deploy-models

Pick by where the deploy trigger lives, not by a fixed tool:

- **solo → cloud** (Cloudflare): direct deploy — `npm run ship`, `wrangler deploy`.
- **solo → own server**: bare git + `post-receive` hook. Push to a `--bare` repo on the
  server; the hook checks out the tree and restarts the service. Deploy = `git push`. The git
  remote goes through a **`~/.ssh/config` alias** (`git remote set-url origin <alias>:path/repo.git`),
  never raw `user@ip:path` — one shared key can serve several hosts, so the **alias** (not the key)
  is what disambiguates host + repo. See `remote-tmux-ops` for the alias/config convention.
- **team → hosting CI/CD**: GitHub Actions / GitLab CI / Gitea Actions — depends on where the repo lives.

**Prod path is CI-first.** When the project has a CI/CD deploy (GitHub Actions etc.), pushing to the
release branch **is** the route to production — reproducible, gated, auditable, and the audited default.
A direct `wrangler deploy` / `npm run ship` from a workstation is a **fallback**: use it only when CI is
insufficient or unavailable (CI down, a hotfix CI can't do) or for **bulk / mass operations** — never as
the routine deploy. A prod-op guard hook can enforce this (direct prod ops require an explicit user
request). So even a Cloudflare project with a `wrangler`-based `ship`/`release` script prefers **push → CI**
whenever a deploy workflow exists.

Cross-cutting for any model:

- pre-deploy verify-gate (lint/test/typecheck) before shipping — do not deploy past the gate;
- decide the rollback method **before** an incident (`wrangler rollback` / push previous
  commit / re-pull previous image);
- order DB migration vs. code deploy explicitly — schema drift breaks running code.

The concrete registry / host / CI is project-specific — the agent resolves it, recorded
in `./.agents/REGISTRY.md`.
