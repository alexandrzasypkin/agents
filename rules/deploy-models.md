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

**Prod path is CI-first.** If a CI/CD deploy exists (GitHub Actions etc.), push → CI is the default route
to production — reproducible, gated, auditable. A manual `wrangler deploy` / `npm run ship` is a fallback:
only when CI is down/insufficient or for bulk/mass ops, and gated behind an explicit request (a prod-op
guard hook can enforce it). The concrete workflow (which branch, which `deploy.yml`) is project-specific.

Cross-cutting for any model:

- pre-deploy verify-gate (lint/test/typecheck) before shipping — do not deploy past the gate;
- decide the rollback method **before** an incident (`wrangler rollback` / push previous
  commit / re-pull previous image);
- order DB migration vs. code deploy explicitly — schema drift breaks running code.

## Per-project deploy runbook — resolve ONCE, then FOLLOW it
A working project has **one** deploy path, not a fresh derivation each session. Re-deriving from this
chain every time is how the same project gets deployed three different ways. So:

- **First deploy:** resolve the concrete path from this chain, then **pin it in `docs/deploy.md`** (a
  committed runbook — dev source of truth, see `project-docs`). It records the *what*, exactly:
  route (CI workflow + branch, or the fallback `wrangler deploy` command), the target names (worker /
  D1 / queue / bucket / unit), secret **names** (values stay in the secret file, sourced via
  `cf-secrets` — never in the runbook), migration-vs-code order, the **verify** URL + expected
  response, and the **rollback** command. `REGISTRY.md` still logs *why* the infra changed — it is not
  the runbook.
- **Every deploy after:** read `docs/deploy.md` and **execute it verbatim**. Do not improvise an
  alternative path. Read the whole skill chain (`deploy-verify` → `deploy-models` → `cf-secrets`)
  before touching prod.
- **Infra actually changed** (new binding, new route)? Update the runbook in the same change — the
  runbook and reality never drift.

If `docs/deploy.md` is absent on a project that clearly ships, writing it IS the first step of the
deploy — not an optional extra.
