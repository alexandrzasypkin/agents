---
name: fastapi-scaffold
description: Stand up a minimal internal Python/FastAPI service. Apply when creating a new service-layer component.
---

# fastapi-scaffold

A minimal, conventional Python service. Quality gate is `quality-py` (ruff / pyright / pytest).

## Packaging
- `pyproject.toml` is the source of truth; the `Dockerfile` installs via `pip install .`.
- No hand-maintained `requirements.txt` by default.

## Structure
```text
services/<name>/
├── Dockerfile
├── pyproject.toml
├── .env.example        # only this in the repo; real values materialize on the server
├── app/
└── deploy/             # service-local deploy templates, if any
```

## Runtime
- One service = one explicit port.
- A `GET /health` endpoint, unless agreed otherwise.
- Minimal, explicit internal contracts; v0 prefers plain response bodies (no shared envelope) unless agreed.
- A service-local venv for checks (`<svc>/.venv/bin/ruff|pyright|pytest`).

Start with a minimal v0 skeleton, then the quality gate, then deploy (`deploy-verify`).
