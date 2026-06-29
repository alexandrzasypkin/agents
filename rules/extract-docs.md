---
name: extract-docs
description: Extract text/data from local documents. Apply when reading PDFs/office files as a source.
---

# extract-docs

- text PDF → text: `pdftotext` (poppler); `-layout` to keep columns.
- docx / odt / rtf → md: `pandoc` (reads office formats natively).
- scanned PDF (OCR): `tesseract` / `ocrmypdf` — only when the source is an image.
- structured/table PDF: `pymupdf` (fitz) / `pdfplumber` — when `pdftotext` loses table structure.

`pandoc` is shared across domains (also office) — configure once, do not duplicate.
OCR / structured-table tools are install-when-needed (project principle).
