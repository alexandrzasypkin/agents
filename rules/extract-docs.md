---
name: extract-docs
description: Read from and produce local documents (PDF, office — docx/xlsx/ods). Apply when reading or generating document/spreadsheet files.
---

# extract-docs

Read from — and produce — local documents (PDF, office). CLI-first; tools are install-when-needed.

## Read
- text PDF → text: `pdftotext` (poppler); `-layout` to keep columns.
- docx / odt / rtf → md: `pandoc` (reads office formats natively).
- **xlsx / ods (spreadsheets)** → csv/data: `libreoffice --headless --convert-to csv`, `xlsx2csv`, or
  `pandas` / `openpyxl` (pandoc does **not** read spreadsheets).
- scanned PDF / image (OCR): `tesseract` / `ocrmypdf` — only when the source is an image. Pass the
  **language(s)** (`--lang rus+eng`) and install the matching **tessdata** packs (default is
  English-only — a common miss). Windows: `tesseract.exe` (UB-Mannheim build), not on PATH → resolve
  the path (like `soffice`) and install the language data.
- structured/table PDF: `pymupdf` (fitz) / `pdfplumber` — when `pdftotext` loses table structure.

## Produce (→ office) — see the `office-convert` skill
- md → **docx**: `pandoc` native (`--reference-doc` for A4 + font). **Do NOT** produce docx by feeding
  HTML to `soffice` — it imports as a *Web document* and tables break; go via pandoc-docx.
- **xlsx / ods**: `openpyxl` / `pandas` (pandoc can't), or `csv → soffice --convert-to`.
- **pptx**: `pandoc --reference-doc` (or `python-pptx`). Programmatic (cell/style): `python-docx`, `odfpy`.

The procedure, table verification (`<w:tbl>` check), A4/reference, and shared hazards (Cyrillic font,
UTF-8, `soffice` lock) live in the **`office-convert`** skill.

## OS note (Windows)
`pandoc` and the Python libs are cross-platform (pip/uv). **LibreOffice** differs: the binary is
`soffice.exe` (in `%ProgramFiles%\LibreOffice\program\`), usually **NOT on PATH** — resolve its path
(like Chrome for playwright), don't assume `libreoffice`. Gotcha: headless `soffice` fails if a
LibreOffice GUI instance is already open (single-instance lock) — close it first.

`pandoc` is shared across domains (also office) — configure once, do not duplicate. LibreOffice / OCR /
table tools are install-when-needed (project principle).
