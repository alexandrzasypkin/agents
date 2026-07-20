---
name: deploy-verify
description: Deploy a self-hosted service, then verify before moving on — rebuild/restart, success markers, health check. Apply when deploying a self-hosted service.
---

# deploy-verify

The verify loop for a self-hosted deploy — `proof-loop` applied to deploying. Extends `deploy-models`.

0. **Read the project's deploy runbook first** (`.agents/runbooks/deploy.md`) and follow it verbatim — same
   project, same path, every time. No runbook yet? Resolve the path from the chain and write it now
   (see `deploy-models` → "Per-project deploy runbook"). Read the whole chain before touching prod.
1. Deploy via the project's trigger (git push → server hook, `systemctl --user restart`, or a
   container rebuild). **No `scp`/`rsync` of code** — git is the transport (see `git-discipline`).
2. **Verify before the next step**: read the deploy output for success markers; hit the service
   `/health`; confirm it is active (`systemctl --user is-active`, `ss`, the container is up).
3. On a crash loop, read logs (`journalctl --user -u <unit>`, container logs) and check restart
   counters before retrying.
4. Decide the rollback method **before** deploying (previous image / previous commit / prior version).

Host names, unit/container names, ports, and hooks are project-specific — see the project.
For remote sessions, use `remote-tmux-ops`.
