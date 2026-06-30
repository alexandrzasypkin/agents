#!/usr/bin/env python3
"""md2pdf — Markdown -> A4 PDF via python-markdown + weasyprint.

Baseline, brand-neutral converter. Styling is external: pass --style <css> (e.g. a project
CSS generalized from the pdf-style template). No project specifics live here.
Deps: pip install markdown weasyprint   (default font: DejaVu Sans).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import markdown
    from weasyprint import HTML
except ImportError as exc:  # pragma: no cover
    sys.exit(f"Missing dependency: {exc}. Install: pip install markdown weasyprint")

DEFAULT_CSS = """
@page { size: A4; margin: 18mm 17mm 16mm 17mm;
  @bottom-right { content: "p. " counter(page) " / " counter(pages);
                  font-family:'DejaVu Sans'; font-size:7.5pt; color:#a1a1aa; } }
body { font-family:'DejaVu Sans', sans-serif; font-size:10pt; line-height:1.5; color:#1c2426; }
h1 { font-size:20pt; margin:0 0 6pt 0; }
h2 { font-size:13pt; margin:18pt 0 6pt 0; padding-bottom:3pt; border-bottom:2px solid #888;
     page-break-after:avoid; }
h3 { font-size:11pt; margin:12pt 0 5pt 0; page-break-after:avoid; }
p { margin:6pt 0; } ul,ol { margin:6pt 0; padding-left:18pt; } li { margin:3pt 0; }
code { font-family:'DejaVu Sans Mono',monospace; font-size:8.6pt; background:#eee;
       padding:0.5pt 3pt; border-radius:3px; }
blockquote { margin:8pt 0; padding:7pt 11pt; background:#f4f4f5; border-left:3px solid #888; }
table { width:100%; border-collapse:collapse; margin:9pt 0; font-size:8.8pt; }
thead { display:table-header-group; }
th { background:#13141c; color:#fff; text-align:left; padding:5pt 7pt; }
td { padding:4.5pt 7pt; border-bottom:1px solid #e2e2e2; vertical-align:top; }
tbody tr:nth-child(even) { background:#f6f6f6; } tr { page-break-inside:avoid; }
"""


def preprocess(md: str) -> str:
    # PDF cannot resolve relative .md links -> de-link them to plain emphasis.
    return re.sub(r"\[([^\]]+)\]\((?!https?:)[^)]*\.md\)", r"*\1*", md)


def render(md: str) -> str:
    return markdown.markdown(
        md,
        extensions=["tables", "fenced_code", "sane_lists", "attr_list", "md_in_html"],
        output_format="html",
    )


def convert(src: Path, out: Path, style: Path | None) -> Path:
    css = style.read_text(encoding="utf-8") if style and style.exists() else DEFAULT_CSS
    body = render(preprocess(src.read_text(encoding="utf-8")))
    html = (f'<!DOCTYPE html><html><head><meta charset="utf-8">'
            f'<style>{css}</style></head><body>{body}</body></html>')
    HTML(string=html).write_pdf(str(out))
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Markdown -> A4 PDF (weasyprint).")
    ap.add_argument("input", type=Path, help="input .md")
    ap.add_argument("-o", "--output", type=Path, default=None, help="output .pdf")
    ap.add_argument("--style", type=Path, default=None,
                    help="external CSS (e.g. a project style from the pdf-style template)")
    a = ap.parse_args(argv)
    out = a.output or a.input.with_suffix(".pdf")
    convert(a.input, out, a.style)
    print(f"PDF: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
