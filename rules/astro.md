---
name: astro
description: Astro 5 + @astrojs/cloudflare conventions (project layout, island hydration, runtime.env, middleware, SSR vs static). Apply when working on an Astro project.
---

# astro

Astro 5 project conventions. The procedure lives in the **`astro` skill** — project layout,
`client:*` hydration directives (pick the laziest that works), Cloudflare bindings via
`Astro.locals.runtime.env`, the `@astrojs/cloudflare` adapter + `platformProxy`, middleware,
`worker-configuration.d.ts` (regen with `wrangler types`), SSR vs static, and the common pitfalls.

Not baked into a domain: **self-config pulls this rule when the project actually uses Astro**
(detected by `astro.config.*` / an `@astrojs/*` dependency) — same on-need model as `delegation`.
Project-specific Astro structure (zone layout, write-boundaries) stays in the project, recorded in
`./.agents/REGISTRY.md`.
