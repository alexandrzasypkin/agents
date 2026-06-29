---
name: deploy-models
description: Deployment model selection. Apply when deploying a project.
---

# deploy-models

Pick by where the deploy trigger lives, not by a fixed tool:

- **solo → cloud** (Cloudflare): direct deploy — `npm run ship`, `wrangler deploy`.
- **solo → own server**: bare git + `post-receive` hook. Push to a `--bare` repo on the
  server; the hook checks out the tree and restarts the service. Deploy = `git push`.
- **team → hosting CI/CD**: GitHub Actions / GitLab CI / Gitea Actions — depends on where the repo lives.

Cross-cutting for any model:

- pre-deploy verify-gate (lint/test/typecheck) before shipping — do not deploy past the gate;
- decide the rollback method **before** an incident (`wrangler rollback` / push previous
  commit / re-pull previous image);
- order DB migration vs. code deploy explicitly — schema drift breaks running code.

The concrete registry / host / CI is project-specific — the agent resolves it, recorded
in `./.agents/REGISTRY.md`.
