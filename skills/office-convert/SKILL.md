---
name: office-convert
description: Produce office files correctly — docx/doc, xlsx/ods, pptx. Apply when generating Word/Excel/PowerPoint-family documents from md/csv/data.
---

# office-convert

Produce office documents the right way. CLI-first; tools install-when-needed. Reading office files
is the `extract-docs` rule; this is the **produce** procedure.

## Shared hazards (all formats)
- **Never round-trip through HTML.** Feeding HTML to `soffice`/libreoffice imports it as a
  *Web document* → table layout collapses, text runs past the page margin. Produce the **native**
  format directly (sections below). This is the #1 cause of "tables came out broken".
- **Cyrillic-capable font is mandatory** in any template / reference doc — the Windows toolchain
  default breaks Cyrillic (□□□). Set the font explicitly (DejaVu Sans / Liberation / Noto); don't
  rely on the default. Font is a **generation parameter**; the **locale is project-level** (separate).
- **UTF-8 in and out**, especially on Windows (`PYTHONUTF8=1`, console `chcp 65001`) — see `env-setup`.
- **Windows `soffice.exe`** lives in `%ProgramFiles%\LibreOffice\program\`, usually NOT on PATH →
  resolve the path (like Chrome for playwright). Headless `soffice` fails if a LibreOffice GUI window
  is open (single-instance lock) — close it first.

## Flowed documents — docx / doc / odt
Path: **md → `pandoc` native `.docx`** → (only if `.doc` is required) → `soffice` repackages to `.doc`.
```bash
pandoc in.md -o out.docx --reference-doc=ref-a4.docx        # native Word tables + page layout
soffice --headless --convert-to doc --outdir out/ out.docx  # .doc as a Writer text doc, not web
```
- **A4:** pandoc's default reference is US **Letter**. For A4, pass `--reference-doc` = a doc whose
  `sectPr` is A4 (and that carries the Cyrillic font).
- **Verify real tables** before shipping — they must be Word tables, not paragraphs:
  ```bash
  unzip -p out.docx word/document.xml | grep -c '<w:tbl>'   # must be > 0
  ```
- `.doc` (Word 97 binary) is **legacy** — only when a downstream tool demands it; otherwise ship `.docx`.
- Fine cell/style control → `python-docx` programmatically.

## Spreadsheets — xlsx / ods
`pandoc` does **not** produce spreadsheets. Use:
- **`openpyxl` / `pandas`** — programmatic: formulas, number formats, multiple sheets, styling.
- **csv → `soffice --headless --convert-to xlsx`** — quick, structure-only (no formulas/formatting).
- `odfpy` for `.ods` specifics.
Watch: number-vs-text cell types (leading zeros, dates lost), and that a sheet isn't one CSV blob.

## Presentations — pptx / odp
`pandoc in.md -o out.pptx --reference-doc=template.pptx` (slide per top heading; 16:9 + Cyrillic font
live in the reference template). Deeper slide control → `python-pptx`. Expand on real need.

## Verify
Open the produced file (or inspect its XML) before declaring done (proof-loop): confirm tables are
real, page size is right, and Cyrillic renders — not □□□.
