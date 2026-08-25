# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The product marketing site for **Turf** (turf.build) — the infrastructure engine built for AI
agents: Terraform-compatible, MCP-native, governed by the plan. Astro static site, deployed to
GitHub Pages at the apex domain via `.github/workflows/deploy.yml` on every push to `main`. There
is no CMS, no backend, no test suite.

## Commands

```bash
npm install
npm run dev      # http://localhost:4321
npm run build    # → dist/
npm run preview  # serve the built output
npm run check    # astro check — types + template diagnostics; the only "test" here
```

Node 22+ (CI pins 22). `npm run check` is the pre-commit gate — run it after editing any `.astro`
frontmatter or inline `<script>`, since those are typechecked under `astro/tsconfigs/strict`.

## Architecture

**One global stylesheet, not scoped styles.** `src/styles/global.css` (~530 lines) *is* the design
system: `:root` custom-property tokens plus every component class (`.band`, `.beat`, `.step`,
`.pillar`, `.tier`, `.matrix`, `.codeblock`, `.term`, …). It is imported exactly once, by
`src/layouts/Layout.astro`. New UI should reuse existing classes and tokens rather than introduce
ad-hoc CSS. Astro `<style>` blocks are the exception, used only for genuinely page-local visuals
(`pages/demo.astro`, `pages/contact.astro`, `components/Solutions.astro`) — and note a scoped rule
may need extra specificity to beat a global one (see `.demo-config .ph pre`).

**Theming is three-way.** Every color token is declared in `:root` (light), in
`@media (prefers-color-scheme: dark)`, *and* in `:root[data-theme="light"]` / `:root[data-theme="dark"]`.
Any new token must be added to all of those blocks, or it will break in one mode. Never hardcode a
hex value in markup — use `var(--ink)`, `var(--ok)`, `var(--muted)`, etc.

**Layout owns all `<head>` concerns.** `Layout.astro` derives the canonical URL and OG image from
`Astro.site`, renders OG/Twitter meta, preloads the self-hosted woff2, and gates the Google Analytics
tag behind `import.meta.env.PROD` (so dev never sends hits). Pages pass only `title` / `description`.
Titles are Turf-leading (`Turf — …`). `TopNav` and `Footer` are rendered by the layout, so pages
render body content only.

**Pages compose components; the home page composes them all.** `pages/index.astro` is nothing but an
ordered list of section components — Hero, UseCases, FearStrip, HowItWorks, CompatibilityTeaser,
Pillars, Flexibility, Partner. Those components carry the home-page anchor ids (`#use-cases` on
UseCases, `#product` on HowItWorks, `#compatibility` on CompatibilityTeaser, `#get-started` on
Footer); cross-page links use a leading slash (`/#product`) so they work from subpages. UseCases
also carries an empty legacy anchor span `#solutions` (it replaced the Solutions section) so
pre-2026-08 inbound links still land — don't remove it. A standalone `/how-it-works` page was
tried and dropped (too thin); the loop lives on home. The home band striping alternates
`band`/`band alt` in the order above — inserting or removing a section means re-checking the
alternation. Subpages follow a fixed shape: `.subhero` → alternating `.section` / `.section alt`
→ `.prose` or a grid.

**Client JS is deliberately near-zero.** The only script is the hero's plan-convergence animation in
`components/Hero.astro` — an inline timeline of `setTimeout` steps that mutate classes/text, with a
`prefers-reduced-motion` branch that jumps straight to `finalState()`. The panel's markup renders the
converged-from state statically so it reads correctly with JS disabled. Keep new interactivity in
this style rather than adding a framework integration.

## Copy and voice rules

This is marketing copy for commercial software with a legally-sensitive competitor relationship.
The following were decided deliberately during authoring; re-deriving them from the rendered site is
not possible, and "improving" the wording usually breaks one of them.

**Trademark.** Terraform® is HashiCorp's mark; OpenTofu™ is the Linux Foundation's. Rules: `®` appears
**once per page, at the first prominent body use** (e.g. the hero lede) — headlines stay clean; the
footer disclaimer carries the attribution + non-affiliation statement on every page. "Terraform" is
only ever used nominatively (compatibility, comparison), never in a product name, domain, or logo.
Never write "the Terraform Registry" — its ToS restricts non-Terraform use; say "module registry",
"modules", or "OpenTofu registry".

**Technical accuracy that copy keeps getting wrong.**
- Say "**OpenTofu framework**", never "OpenTofu engine" — Turf does *not* use OpenTofu's planner or
  execution engine, and "engine" misstates the product. Also never "upstream OpenTofu", just "OpenTofu".
- Turf produces the plan; the *agent* does not. Avoid phrasing that implies the agent thinks up a plan.
- The framing is "**the Terraform plan becomes the agent's TODO list**" (directional), not "the agent's
  TODO list is the plan".
- `turf up /path/to/config` is invalid syntax. The correct form is `turf -C /path/to/config up`; the
  site prefers showing `cd path/to/config && turf up`.
- Don't promise undo/rollback — Turf doesn't support it.
- Say "Local AI models and GPU clouds", not "local models". Say "OPA policy checks" for the policy example.
- Unshipped capabilities are framed as "coming soon", never as gaps or absences — **at the
  capability level** (the Pillars grid, the compatibility matrix). The five *use-case narratives*
  are deliberately written present-tense with no shipped/coming-soon distinction (decided
  2026-08-25; the site is forward-looking because development is fast).
- **Never name or describe Restate** or any internal scale-out mechanism (virtual objects,
  workflows, journals). Scale claims use capability framing: "the cloud API is the ceiling",
  "thousands of resources per stack", "durable execution".
- **"Drop-in replacement" never leads** (de-emphasized 2026-08-25; greenfield-first). Compatibility
  is a supporting message: say "Terraform-compatible" or "runs your existing configurations — HCL,
  modules, providers — unchanged". The provenance line ("independent product built on the OpenTofu
  framework") stays.

**Tone.** No lean-startup vocabulary in public copy — in particular avoid "pain" / "pain point". Do not
imply existing design partners, customers, or a team the company doesn't have. Page `<title>`s are
Turf-leading (`Turf — …`).

**Locked messaging.** The hero headline is "**The infrastructure engine built for AI agents.**"
(adopted 2026-08-25, superseding "Control your infrastructure AI with Terraform plans."). The site
carries **five positioning pillars** — Terraform at 10x scale · datacenter automation · autonomous
products · governed AI operations · agentic IaC/MCP-native — rendered as the home UseCases section.
The internal source of truth for all of this (messages, audiences, proof points, approved phrases,
what not to say) is the touchstone doc at `headquarters/marketing/use-cases.md` — start there for
any copy round. Treat the headline as fixed unless the user reopens it.

## Constraints that are easy to violate

- `compressHTML: false` in `astro.config.mjs` is intentional — Astro's default whitespace trimming
  glues words together when a `<strong>`/`<a>`/`<code>` wraps onto its own source line. Don't re-enable.
- **Literal `{` / `}` inside `<pre>` must be escaped as `&#123;` / `&#125;`.** Astro parses them as JSX
  expressions and the build dies with a hard `CompilerError`. Every HCL/JSON sample on the site
  (`get-started`, `compatibility`, `demo`) is written this way.
- `public/CNAME` carries the custom domain into every build. Deleting it breaks the apex domain.
- There is no `base` in the Astro config, so assets are root-absolute (`/_astro/`, `/fonts/`). The
  site only works served from a domain root — a `turfbuild.github.io/website/` preview 404s its assets.
- The footer trademark fineprint must appear on every page — it lives in `Footer.astro`, so don't
  bypass the layout.
- If you touch dependencies, regenerate the lockfile cleanly
  (`rm -rf node_modules package-lock.json && npm install`). A lockfile from a targeted
  `npm install <pkg>` on macOS omits Linux-only optional native deps and CI's `npm ci` fails EUSAGE.
- `dist/` is build output listed in `.gitignore`; never hand-edit it.
- There is no mobile hamburger menu — below 860px `.nav-links a:not(.btn)` is hidden and only the CTA
  shows. Adding a nav link means it's desktop-only unless you also add it to the footer sitemap.

## Content provenance

`pages/compatibility.astro` is adapted from the internal conformance report at
`doof/docs/development/analysis/language-feature-conformance.md`. When syncing it: strip `FU-####`
ids, `internal/…​.go:NNN` code anchors, and design-doc paths; the "Known divergences" section was
removed on purpose (inaccurate and off-message) — don't reinstate it.

`pages/demo.astro` mirrors the kind-crd example at `turfbuild/turf-examples`; the phase labels and
effects shown in the HCL diagram are exactly what `turf up` computes, so they must be re-checked
against a real run rather than hand-authored. Demo videos live in `public/demos/` as webm+mp4 pairs
with poster PNGs.

## Working style the user expects

Build, then **pause for a local preview before committing** — the user reviews the rendered page and
says "publish" explicitly. Deploy is just a push to `main`.

## Regenerating the OG image

`public/og.png` (1200×630) is rasterized from `scripts/og.svg`, authored on a 1200×1200 canvas with
content in the middle 630-row band:

```bash
qlmanage -t -s 1200 -o /tmp/ogout scripts/og.svg
cp /tmp/ogout/og.svg.png public/og.png
sips -c 630 1200 public/og.png
```

The README also carries the one-time GitHub Pages + GoDaddy DNS go-live runbook and the Buttondown
newsletter setup — consult it before touching hosting or the footer subscribe form.
