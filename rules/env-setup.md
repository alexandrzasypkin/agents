---
name: env-setup
description: Environment setup — global vs local installs and package-manager choice. Apply when installing dependencies or scaffolding a project.
---

# env-setup

## Global vs local
- Project dependencies → **local** (node_modules / project venv). Never global for a project dep.
- Global → only cross-project dev CLIs not pinned to a project version (the package managers
  themselves, ruff via pipx). Commit lockfiles (reproducibility). gitignore artifacts:
  `node_modules/`, `.venv/`, `venv/`, `__pycache__/`.

Quality tools follow the same rule, by **coupling to the project's dependency tree**:

- coupled (needs the project's plugins / venv packages) → **local**: eslint, prettier,
  pyright, pytest, vitest, black. Run via npx / the project venv.
- standalone binary, config-only → **global** ok: ruff, shellcheck, clang-tidy, clang-format.
  Pin per-project only when version reproducibility matters.
- cross-cutting media / doc / retrieval CLIs → **global**, installed **when a project needs them**:
  ffmpeg, imagemagick, **yt-dlp**, pandoc, pdftotext, tesseract. Standalone binaries, no project
  coupling (yt-dlp fetches video + subtitles for `search-escalation` / `media`).

## Manager by language
- New project: Node → **pnpm**, Python → **uv** (no migration cost, faster, lockfile).
- Existing project: use what is already there — detect by lockfile (`package-lock.json`→npm,
  `pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn; `uv.lock`→uv, `poetry.lock`→poetry,
  `requirements.txt`→pip+venv, `Pipfile`→pipenv).
- npx — one-off CLI without install (`npx wrangler deploy`); frequent use → devDependency.

## Prohibitions
[CRITICAL] Do not install project dependencies globally.

- Do not mix managers in one project (no npm + pnpm; no pip + poetry).
- Do not migrate a working project's manager without a reason.
- Do not commit artifacts; do commit lockfiles.
