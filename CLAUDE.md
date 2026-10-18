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
`Astro.site`, renders OG/Twitter meta (including the image's declared type/dimensions/alt, so
scrapers that never fetch `og.png` still render a full card), preloads the self-hosted woff2, and
gates the Google Analytics tag behind `import.meta.env.PROD` (so dev never sends hits). `TopNav` and
`Footer` are rendered by the layout, so pages render body content only. The one exception is the
`banner` slot, rendered above `TopNav`: only home fills it, with `components/Announcement.astro`, the
interim *Metal to Tokens* strip (10/16; since 10/18 it links `/reference-architectures/`). It goes
when the launch site build puts the announcement in the hero's CTA row (launch plan §8).

Pages pass four props, all optional: `title`, `description`, `noindex`, `jsonLd`.
- **`noindex`** emits `robots: noindex,follow` *and* suppresses `canonical`/`og:url` — only `404.astro`
  uses it. A self-canonical pointing at a route that doesn't exist is worse than no canonical.
- **`jsonLd`** takes a schema.org node or array of them and renders each through
  `components/JsonLd.astro` (`set:html` + `is:inline`, which keeps Astro from parsing the JSON's
  braces as JSX). **Never hand-write an `application/ld+json` script tag into a page.** Home carries
  `Organization` + `WebSite` + `SoftwareApplication` cross-referenced by `@id`; the two demo pages
  carry `VideoObject` per screencast; `/demo/scalr/` and `/reference-architectures/` carry a
  `BreadcrumbList`, and the paper's page is a `TechArticle` whose `associatedMedia` is the PDF.
  The `SoftwareApplication` node **deliberately omits `offers`** — a `price: 0` would assert the
  product is free for everyone, when commercial use is licensed (`/pricing/`, `/licensing/`); its
  `license` points at `/licensing/` instead. Don't add an offer.
- **Titles stay Turf-leading (`Turf — …`)** — reaffirmed 2026-08-25 — but must earn the full SERP
  budget: aim 50-60 characters and put query terms after the dash (`Turf — Get started: install the
  CLI and MCP server`, not `Turf — Get started`). **Descriptions run 140-158 characters, plain text**
  — no backticks or markdown; they render literally in a result snippet.

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

**Trademark.** Turf™ is Turf LLC's mark, unregistered: the filing is in flight, and `™` stays
until registration issues. Terraform® is HashiCorp's. Ansible® is Red Hat's, whose guidelines
(<https://docs.ansible.com/projects/ansible/latest/dev_guide/style_guide/trademarks.html>) ask for
the symbol on the first reference. Helm® and Kubernetes® are registered marks, and OpenTofu™ a
trademark, of the Linux Foundation (<https://www.linuxfoundation.org/legal/trademarks>, "immediately
after the first usage"); Prometheus® joins that clause if the site ever names it (the PDF does).
Rules: the symbol appears **once per page, at the first prominent body use** (the hero lede on
home, "Turf™ plans, applies, …"; a subpage's lede) — headlines, `<title>`s, eyebrows, buttons and
code stay clean; a mark is never possessive or plural ("Ansible playbooks", not "Ansible's"); the
`turf.build` wordmark itself is unmarked, as in the PDF. The footer fineprint carries the attribution
and non-affiliation statement on every page, and `public/llms.txt` the same block: "Turf™ is a
trademark of Turf LLC. Terraform® is a registered trademark of HashiCorp, Inc. Ansible® is a
registered trademark of Red Hat, Inc. in the United States and other countries. Helm® and
Kubernetes® are registered trademarks, and OpenTofu™ is a trademark, of the Linux Foundation. Turf
is not affiliated with, endorsed by, or sponsored by HashiCorp, IBM, Red Hat, the Linux Foundation
or the OpenTofu project." "Terraform" is only ever used nominatively (compatibility, comparison),
never in a product name, domain, or logo. Never write "the Terraform Registry" — its ToS restricts
non-Terraform use; say "module registry", "modules", or "OpenTofu registry". (Decided 2026-10-03
while the neocloud PDF was marked — source of truth: the Marks section of
`headquarters/marketing/launch/refarch-neocloud.md` — and applied site-wide 2026-10-18, except
`get-started.astro`, left to the install round.)

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
  "thousands of resources per stack", "durable execution". The one exception is `/telemetry/`, a
  disclosure that names restate-server as the engine reports it (see Content provenance).
- **"Drop-in replacement" never leads** (de-emphasized 2026-08-25; greenfield-first). Compatibility
  is a supporting message: say "Terraform-compatible" or "runs your existing configurations — HCL,
  modules, providers — unchanged". The provenance line ("independent product built on the OpenTofu
  framework") stays.

**Tone.** No lean-startup vocabulary in public copy — in particular avoid "pain" / "pain point". Do not
imply existing customers, pilots, partners, or a team the company doesn't have: seeking pilot users
is fine, naming one is not. Since 2026-10-14 the launch is Turf 1.0, "available now": never "beta",
"alpha", "design partner", "evaluation license", "on request" or "waitlist" in copy, and the license
terms are those of `headquarters/marketing/licensing.md` (launch plan §4). Page `<title>`s are
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
- **Internal route links must end in a trailing slash** (`/get-started/`, not `/get-started`). The
  build emits directory routes, so the canonical and the sitemap both carry one, and GitHub Pages
  301s anything else — a slashless link costs a redirect on every click and every crawl.
  `trailingSlash: 'always'` makes the dev server fail on it rather than let it through. Asset paths
  (`/fonts/…`, `/demos/….mp4`) and anchors (`/#product`) must *not* get one.
- The sitemap's per-page `lastmod` comes from `git log` inside `astro.config.mjs`, which is why the
  deploy workflow pins `fetch-depth: 0`. Under the default shallow checkout `git log` returns nothing
  for most paths and every lastmod silently disappears in CI while still working locally.
- `public/llms.txt` is public marketing copy under all the voice rules below — update it when routes,
  pillars, or the headline change. `public/logo.png` exists only as `Organization.logo` for JSON-LD;
  no page loads it.
- `public/CNAME` carries the custom domain into every build. Deleting it breaks the apex domain.
- There is no `base` in the Astro config, so assets are root-absolute (`/_astro/`, `/fonts/`). The
  site only works served from a domain root — a `turfbuild.github.io/website/` preview 404s its assets.
- The footer trademark fineprint must appear on every page — it lives in `Footer.astro`, so don't
  bypass the layout.
- If you touch dependencies, regenerate the lockfile cleanly
  (`rm -rf node_modules package-lock.json && npm install`). A lockfile from a targeted
  `npm install <pkg>` on macOS omits Linux-only optional native deps and CI's `npm ci` fails EUSAGE.
- `dist/` is build output listed in `.gitignore`; never hand-edit it.
- **Papers live in `public/papers/`.** `public/reference-architectures/turf-neocloud-reference-architecture.pdf`
  is a symlink to the `papers/` copy, kept so the first URL still works (GitHub Pages can't redirect a
  PDF); the build writes a real file at both paths. Replace a new version in `papers/` only, and never
  delete the symlink. Links we share go through Scarf, `https://get.turf.build/papers/<file>.pdf`, which
  counts the click and redirects to `https://turf.build/papers/<file>.pdf`. Our own pages may tag the
  link (home's banner adds `?src=home-banner`; Scarf stores the query and passes it through the
  redirect); links in other people's files stay plain. `pages/reference-architectures.astro` is the
  paper's page: its abstract, at-a-glance ideas, chapter list and marks note are the text of record,
  `headquarters/marketing/launch/refarch-neocloud.md` (the intro, "At a glance", the chapter titles
  and the Marks section), so a new paper version means re-checking the page against it. Its
  download button is the Scarf link with `?src=refarch-page`; the home banner links the page.
  `public/papers/turf-neocloud-reference-architecture-cover.jpg` is page 1 of the PDF
  (`qlmanage -t -s 1600` on the PDF, `sips -Z 960`, then JPEG at quality 82); re-render it when the
  cover changes.
- There is no mobile hamburger menu — below 860px `.nav-links a:not(.btn)` is hidden and only the CTA
  shows. Adding a nav link means it's desktop-only unless you also add it to the footer sitemap.

## Content provenance

`pages/compatibility.astro` is adapted from the internal conformance report at
`doof/docs/development/analysis/language-feature-conformance.md`. When syncing it: strip `FU-####`
ids, `internal/…​.go:NNN` code anchors, and design-doc paths; the "Known divergences" section was
removed on purpose (inaccurate and off-message) — don't reinstate it.

`pages/telemetry.astro` mirrors turf's public `docs/telemetry.md`
(`github.com/turfbuild/turf`) field for field: every field, value, switch and precedence rule is
copied exactly, and only the layout is the site's. When the engine's telemetry schema changes, the
doc changes first and this page second. It is a disclosure, so it names restate-server and the
`restate_version` field as the engine reports them, the one site page where Restate is named
(launch plan §4.2, decided 2026-10-16). It promises no retention period, because Scarf's terms
and DPA set none.

`pages/licensing.astro` and `pages/pricing.astro` draw every sentence from
`headquarters/marketing/licensing.md` ("Copy to publish" and "Who gets what"): PolyForm Noncommercial
1.0.0, the Common Paper Pilot Agreement (free, 60 days) and Software License Agreement (the 1.1
Standard Terms are linked), one binary, no license key, `licensing@turf.build`. The license sentence
and the telemetry sentence are byte-identical to that document's (a launch hard line), and there are
no prices (launch plan D20). The "Source" section mirrors turf's README License section (the CLI's
source is MPL-2.0; Turf as a whole is PolyForm). Change the document first, then the page. The pilot
band on home (`components/Partner.astro`) and `/contact/` repeat those sentences.

`public/install.sh` is the installer behind `curl -fsSL https://get.turf.build/install.sh | bash`
(the line the PDF prints from v0.20; `get.turf.build/install.sh` is the Scarf file package
`turf-install-script`, which counts the fetch and redirects to `turf.build/install.sh`, the
script itself). It is POSIX `sh`, a static asset (no trailing slash),
and nothing in the build checks it: run `shellcheck -s sh` and `dash -n` on it before pushing. With
Homebrew it installs `restatedev/tap/restate-server turfbuild/tap/turf`, both named because
Homebrew 7 refuses an unnamed formula from a second third-party tap, and starts the service;
without, it unpacks the release archive and restate-server into `~/.turf/bin`, and the user runs
`turf-mcp-server engine run`
(launch plan D17, decided 2026-10-16). Until a release with the engine is Latest on
`turfbuild/turf`, it prints "Turf 1.0 isn't available yet" and exits 1. It copies from other repos,
so change it when they change:
- the release gate reads `checksums.txt` for `turf_<tag>_<os>_<arch>.tar.gz` and a
  `turf-engine-<os>_<arch>` line (turf's `.github/workflows/release.yml`);
- `RESTATE_VERSION` and its four sha256 pins are the restate-server the engine is tested on (doof
  CI); bump them together, from the `.sha256` files on Restate's GitHub release;
- `resolve_telemetry` is doof's `telemetryconf.Resolve`, and the `engine status` lines it reads
  come from doof's `cmd/turf-mcp-server/engine.go`;
- its license and telemetry sentences come from `headquarters/marketing/licensing.md`. It names
  restate-server, as install surfaces may (launch plan §4.2, D18).

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
