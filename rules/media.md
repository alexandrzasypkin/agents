---
name: media
description: Terminal media processing (ffmpeg, imagemagick) for content/design assets. Apply when transcoding, editing, or generating image/video/gif from the CLI.
---

# media

CLI-first media — no GUI editor in the loop, so operations are repeatable and scriptable.
Linux-reference tools; the agent inventories its environment (they may be absent on Windows —
install or use an equivalent).

- **ffmpeg** — video/audio/gif: transcode, frame extraction, text/watermark overlay,
  pixelate, subtitles, batch, contact sheets. Vetted commands → `ffmpeg-recipes`.
- **imagemagick** — raster: resize, format convert, WebP, composition.

Prefer a one-liner or a small loop over manual editing. Pick quality vs size vs speed per the
target channel (SMM clip, web asset, print).
