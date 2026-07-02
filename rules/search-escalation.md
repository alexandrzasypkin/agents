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

## Video / audio / voice sources (YouTube, Vimeo, podcasts, live/recorded streams — retrieval)
Use **yt-dlp** (CLI, no API key, 1000+ sites) plus local **whisper** for speech. Reading/hearing a
source ≠ watching it — pull the text, cheapest tier first:

- **subtitles / captions (cheapest):** prefer real uploaded subs, fall back to auto-ASR.
  `yt-dlp --list-subs <url>` shows what exists; `--write-sub --sub-lang <lang> --skip-download`
  grabs human subtitles, `--write-auto-sub` the auto-generated ones. Read the `.vtt`/`.srt` as the
  transcript. `--sub-format srt/best` and `--convert-subs srt` normalize the format.
- **no subtitles → speech-to-text:** for uncaptioned video, **podcasts, or streams**, or when only
  an audio stream is reachable — get the audio (`yt-dlp -x --audio-format mp3 <url>`, or `ffmpeg` to
  capture a stream URL / a live `yt-dlp` recording), then transcribe **locally with whisper**
  (whisper.cpp / faster-whisper — no API key). A cloud S2T (Whisper API / Deepgram / AssemblyAI) →
  **project-bound MCP** only if local whisper can't keep up (scale, diarization, real-time).
- **metadata:** `yt-dlp --dump-json <url>` — title, description, chapters, duration, channel, views.
- **search:** `yt-dlp "ytsearch10:<query>" --dump-json`.

Escalate to the full browser (Playwright, level 3) only for interactive/authed video pages yt-dlp
can't reach. The official YouTube Data API (structured search at scale, comments, analytics) → a
**project-bound MCP** (OAuth/key, REGISTRY) — not needed to read/transcribe. `yt-dlp` is a
standalone CLI, installed when needed (see `env-setup`).
