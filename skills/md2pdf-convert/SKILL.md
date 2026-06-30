---
name: md2pdf-convert
description: Convert Markdown to an A4 PDF (python-markdown + weasyprint). Apply when producing a shareable PDF document from markdown.
---

# md2pdf-convert

The `md2pdf` rule's default path — weasyprint, no headless browser (WSL2-friendly).

Pipeline: markdown -> preprocess -> markdown->HTML -> styling (CSS) -> weasyprint -> PDF.

## Run
```bash
python3 scripts/convert.py <input.md> -o <output.pdf> [--style <css>]
```
Deps: `pip install markdown weasyprint`. Font: DejaVu Sans (Cyrillic + diacritics + −≈→⚠).

## Styling / branding is project-specific
`scripts/convert.py` ships a neutral built-in style. Branding (palette, logo masthead,
priority badges, confidence markers) belongs to the **project** — pass `--style` with a
project CSS generalized from the `pdf-style` template. Do not hardcode brand specifics in
the baseline script.

## mermaid (optional +1 step)
weasyprint runs no JS. To include mermaid: preprocess ```` ```mermaid ```` blocks -> mmdc ->
SVG -> inline into the HTML. Fallback (no Chromium/mmdc): keep the code block + a disclosure
note, do not fail. See the `md2pdf` rule for the path choice (weasyprint vs Playwright vs LaTeX).

## Verify
Open/inspect the produced PDF before declaring done (proof-loop).
