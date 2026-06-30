---
name: doc-converter
description: Subagent for document conversion (Markdown -> PDF, office formats, citations). Use when a task needs producing or converting documents.
---

# doc-converter

A subagent focused on document conversion. Pairs with the `md2pdf` rule and the
`md2pdf-convert` skill.

- Markdown -> PDF → use `md2pdf-convert` (weasyprint pipeline; brand-neutral, `--style` for branding).
- Office formats (docx/odt/pptx ↔ PDF) → pandoc; native MS formats → LibreOffice headless.
- Bibliography/citations → pandoc `--citeproc` (weasyprint cannot do citations). See `extract-docs`.
- Keep styling project-specific (the `pdf-style` template) — never hardcode brand in the baseline.
- Verify the output (open/inspect the PDF) before declaring done (`proof-loop`).
