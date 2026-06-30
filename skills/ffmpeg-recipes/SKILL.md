---
name: ffmpeg-recipes
description: Vetted ffmpeg command recipes (transcode, gif, frame, overlay, blur, watermark, batch, tile). Apply when processing video/audio/gif from the CLI.
---

# ffmpeg-recipes

Ready ffmpeg one-liners so you do not guess the syntax. Replace `in.*`/`out.*` and paths.
ffmpeg may be absent on some systems (install-when-needed; see `env-setup`).

## Transcode + scale
```bash
ffmpeg -i in.mp4 -c:v libvpx-vp9 -vf "scale=640:-1" out.webm
```

## GIF with an optimized palette (good quality, small size)
```bash
ffmpeg -i in.mp4 -filter_complex "[0:v]fps=12,scale=480:-1,split[a][b];[a]palettegen=max_colors=64[p];[b][p]paletteuse" out.gif
```

## Extract one frame at a timecode
```bash
ffmpeg -ss 00:00:07.00 -i in.mp4 -frames:v 1 frame.jpg
```

## Text overlay
```bash
ffmpeg -i in.jpg -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:text='Caption':fontsize=48:x=40:y=40:fontcolor=white" out.jpg
```

## Pixelate / blur a region
```bash
ffmpeg -i in.png -filter_complex "[0]crop=50:20:470:20[c];[c]scale=iw/5:ih/5,scale=iw*5:ih*5[px];[0][px]overlay=470:20" out.png
```

## Watermark (overlay a PNG, bottom-right, semi-transparent)
```bash
ffmpeg -i in.jpg -i wm.png -filter_complex "[1]format=rgba,colorchannelmixer=aa=0.8[wm];[0][wm]overlay=W-w-20:H-h-20" out.jpg
```

## Burn-in subtitles
```bash
ffmpeg -i in.mp4 -vf "subtitles=subs.srt" out.mp4
```

## Batch a folder
```bash
for f in *.mp4; do ffmpeg -i "$f" -vf "scale=720:-1" "${f%.mp4}-720.mp4"; done
```

## Contact sheet (tiled preview from sampled frames)
```bash
ffmpeg -i in.mp4 -vf "fps=1/8,scale=480:-1,tile=4x3:padding=4" preview.jpg
```

Quality vs size vs speed is a trade-off (codec, scale, fps, crf); pick per the target channel.
