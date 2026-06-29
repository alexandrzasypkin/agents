---
name: viz-data
description: Data processing and visualization choice. Apply when transforming data or producing charts.
---

# viz-data

Visualization — pick by output, not by habit:

- PDF / document → matplotlib (PNG/**SVG**); SVG embeds straight into a weasyprint PDF (office). Cheapest.
- interactive web / dashboard → plotly (generates HTML/JS from Python).
- bespoke hand-built JS (D3 / chart.js) → last resort only; do not hand-write JS charts when plotly does it from Python.

Processing engine (separate from viz):

- polars → heavy ETL / aggregation / data >~GB (Rust, multicore, lazy).
- pandas → the ML boundary (sklearn), small data, string regex. polars hands off via `.to_pandas()`.
- DuckDB → optional, for SQL-shaped tasks over files/Arrow.

Not either-or — the agent picks the track by the task.
