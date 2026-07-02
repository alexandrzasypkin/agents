---
name: search-escalation
description: Source-retrieval ladder for research. Apply when searching the web for information.
---

# search-escalation

Search is a ladder, not a flat attempt. Escalate — do not stop at level 1:

1. **websearch** — open results, first pass.
2. **fetch the page** — when websearch returned only a snippet, pull the full URL.
3. **full browser** (Playwright) — JS render, pagination, soft-paywall, sites closed to fetch.

[CRITICAL] "Not found" is allowed only after the ladder is exhausted, not at level 1.
Report which level produced the result (fallback-with-disclosure).

## Video sources (YouTube, Vimeo, TikTok, … — retrieval, not just processing)
Use **yt-dlp** (CLI, no API key, 1000+ sites). Reading a video ≠ watching it — pull the text:

- **subtitles / captions:** prefer real uploaded subs, fall back to auto-ASR.
  `yt-dlp --list-subs <url>` shows what exists; `--write-sub --sub-lang <lang> --skip-download`
  grabs human subtitles, `--write-auto-sub` the auto-generated ones. Read the `.vtt`/`.srt` as the
  transcript. `--sub-format srt/best` and `--convert-subs srt` normalize the format.
- **metadata:** `yt-dlp --dump-json <url>` — title, description, chapters, duration, channel, views.
- **search:** `yt-dlp "ytsearch10:<query>" --dump-json`.

Escalate to the full browser (Playwright, level 3) only for interactive/authed video pages yt-dlp
can't reach. The official YouTube Data API (structured search at scale, comments, analytics) → a
**project-bound MCP** (OAuth/key, REGISTRY) — not needed to read/transcribe. `yt-dlp` is a
standalone CLI, installed when needed (see `env-setup`).
