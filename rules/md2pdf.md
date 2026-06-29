---
name: md2pdf
description: Markdown → PDF pipeline for documents. Apply when producing a shareable PDF from markdown.
---

# md2pdf

Default pipeline (text/tables/light diagrams, e.g. branded reports):

- python-markdown (md → HTML) → weasyprint (HTML+CSS → PDF). No headless browser → WSL2-friendly.
- Font: DejaVu Sans (Cyrillic + Serbian diacritics). Template style is a `templates/` asset.

mermaid: weasyprint runs no JS. Preprocess ```` ```mermaid ```` → mmdc → SVG → inline.
Fallback: no Chromium → leave the code block + a disclosure, do not fail.

Other classes (not the default):

- many diagrams + modern CSS, **native Linux only** → Playwright (headless Chromium) HTML→PDF (renders mermaid in one pass; not on WSL2);
- bibliography/citations → pandoc `--citeproc` path (weasyprint cannot do citations);
- academic/technical volumes >40pp → LaTeX (LuaLaTeX + latexmk + Biber). Conscious choice, not default.

Chain: skill `md2pdf-convert` (procedure), template `pdf-style`, MCP `pandoc` (for citations/office formats).
