# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The product marketing site for **Turf** (turf.build) — a new engine for infrastructure as code:
Terraform-compatible, built on OpenTofu, driven by AI agents over MCP, governed by the plan. Astro
static site, deployed to
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

**One global stylesheet, not scoped styles.** `src/styles/global.css` (~730 lines) *is* the design
system: `:root` custom-property tokens plus every component class (`.band`, `.beat`, `.step`,
`.feature`, `.codeblock.rounds`, `.stackbuild`, `.agentloop`, `.eco-grid`, `.fig` and the `.f-*`/`.s-*`
figure utilities, `.toolgrid`, `.tier`, `.matrix`, `.codeblock`, `.term`, …). It is imported exactly
once, by `src/layouts/Layout.astro`. New UI should reuse existing classes and tokens rather than
introduce ad-hoc CSS. Astro `<style>` blocks are the exception, used only for genuinely page-local
visuals (`pages/demo.astro`'s video figure, `pages/contact.astro`, `pages/engine.astro`'s two-layer
frame) — and note a scoped rule may need extra specificity to beat a global one (the global
`.codeblock.rounds .round pre` outranks `.codeblock pre` the same way). Grid children that hold a
`<pre>` need `min-width: 0` (the new grids set it) or the column grows to the longest line.

**Theming is three-way.** Every color token is declared in `:root` (light), in
`@media (prefers-color-scheme: dark)`, *and* in `:root[data-theme="light"]` / `:root[data-theme="dark"]`.
Any new token must be added to all of those blocks, or it will break in one mode. Never hardcode a
hex value in markup — use `var(--ink)`, `var(--ok)`, `var(--muted)`, etc. The six stack-layer
tokens (`--stack-host` … `--stack-workload`, each with an `-ink` partner for text on it) and
`--fig-stroke` were added 2026-10-20 for the hero's stack and the ported figures; their light values
are the paper's, the dark ones keep the ramp legible.

**Layout owns all `<head>` concerns.** `Layout.astro` derives the canonical URL and OG image from
`Astro.site`, renders OG/Twitter meta (including the image's declared type/dimensions/alt, so
scrapers that never fetch `og.png` still render a full card), preloads the self-hosted woff2, and
gates the Google Analytics tag behind `import.meta.env.PROD` (so dev never sends hits). `TopNav` and
`Footer` are rendered by the layout, so pages render body content only. The one exception is the
`banner` slot, rendered above `TopNav`: only home fills it, with `components/Announcement.astro`: the
*Metal to Tokens* strip until the 1.0 release (10/16; from 10/18 it linked `/reference-architectures/`),
the Turf 1.0 strip linking `/engine/` from the release on (launch plan §8).

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
ordered list of section components (redesigned 2026-10-20, revised 10-21): FigureDefs, Hero (with
StackBuild), WhyEngine (two figures: the engine map and a run timeline), HowItWorks, ActionsInPlan,
AgentInLoop, CompatibilityTeaser (three ecosystem cards), OpsEnvironment (the ops-environment band,
moved from `/use-cases/` on 2026-10-21: the lane figure, the backend/registry/ephemeral HCL, a
ticklist, proof links), Engine, UseCasesTeaser, Flexibility, Partner. Those components carry the
home-page anchor ids (`#product` on HowItWorks, `#compatibility` on CompatibilityTeaser,
`#ops-environment` on OpsEnvironment, `#use-cases` on UseCasesTeaser, `#get-started` on Footer);
cross-page links use a leading slash (`/#product`) so they work from subpages. UseCasesTeaser also
carries an empty legacy anchor span `#solutions` (the 2026-08 UseCases section replaced Solutions,
then SolutionsTeaser replaced UseCases, then the name went back to use cases on 2026-10-21) so old
inbound links still land — don't remove it. A
standalone `/how-it-works` page was tried and dropped (too thin); the loop lives on home. The home
band striping alternates `band`/`band alt` in the order above (WhyEngine is the first `alt`) —
inserting or removing a section means re-checking the alternation. Subpages follow a fixed shape:
`.subhero` → alternating `.section` / `.section alt` → `.prose` or a grid. `pages/use-cases.astro`
is the four-use-case page (one section per job, each: who it's for, a figure, HCL, Day 1 / Day 2
beats, proof links, a CTA; ids `gpu-clouds`, `kubernetes-fleets`, `installers`, `agents`); the home
teaser cards (`.solutions.four`, a 2×2 grid) link `/use-cases/#<id>`. "Your ops environment" was its
§04 until 2026-10-21, when it moved to the home band (a property of the engine, not a job). Since 2026-10-21 `installers` carries no HCL
block: its figure is the convergence loop between the product (north, an internal web app) and the
customer's cloud account (south), and the installer's steps live in the linked example. In `agents`,
tool and skill names carry no underscores ("skill: authoring HCL", "provider search · describe",
"awaiting approval"); HCL resource types keep theirs. It was `/solutions/` for one unpublished
day (2026-10-20); nothing ever linked it. Every section's HCL is
quoted from `turfbuild/turf-examples` where a file exists, and captioned "after …" or "illustrative"
where it is adapted; keep that honesty when editing. Neither page links the pre-1.0 demo recordings
(`/demo/`, `/demo/scalr/`): a 1.0 recording is coming, and the nav's "Demo" item is the only route
to them until then. The Turf console is not in 1.0, so its stills (`public/console/`) carry a
`coming soon` pill wherever they appear; they render through `components/Still.astro`, which
enlarges the still on click with the HTML popover API (top layer, light dismiss, no script;
pre-2024 browsers get an inert button). Figures that show an unshipped capability (the engine
nodes and per-provider flow control in FanOutFigure) tag it `COMING SOON` inside the SVG and say
what is shipped and what is coming in the `.figcap` beside it.

**Client JS is deliberately near-zero.** The only script is the cookie consent. The hero's stack
build-out (`components/StackBuild.astro`) is CSS keyframes in global.css: one 12 s clock, every
element on its own keyframes over the same period (per-element `animation-delay` with `infinite`
never resets together), and each layer carries the *whole* `animation` shorthand — a nameless
`animation: 12s …` base rule is minified to `animation: none`. The HCL line inside a layer is not
animated on its own: a compositor-animated opacity on text inside an animated layer rasterizes blank
in Chrome, so it appears with its layer. The markup is the assembled state, so
it reads correctly with CSS off and under `prefers-reduced-motion` (which sets `animation: none`).
The box is a 16:10 slot a `<video class="stackbuild">` will take when the kinetic-typography video
exists. Keep new interactivity in this style rather than adding a framework integration.

**Figures are inline SVG ported from the reference architecture.** `components/figures/*.astro`
carry Figure 1 (StackFigure), Figure 8 (ShellVsTurfFigure) and Figure 9 (FleetFigure) of
`headquarters/marketing/launch/refarch-neocloud.html`, plus five drawn in the same grammar
(FanOutFigure, InstallerFigure, OpsEnvFigure, and WhyEngine's EngineMapFigure and
RunTimelineFigure, whose lanes follow the console's grammar). Geometry is the paper's; every `fill`/`stroke` is a
class from the `.f-*`/`.s-*` utilities and every text a `.t-*` class, so the figures re-theme (never
`fill="#…"` or `fill="var(--…)"` attributes). Marker defs live in `components/FigureDefs.astro`,
rendered once per page at the top of the layout slot (`position:absolute`, not `display:none`:
Safari drops markers from a hidden tree); ids are page-global, so never render a figure twice on a
page. Figure 9's racks, a load-time script in the paper, are generated in the component's
frontmatter. Console stills come from `headquarters/marketing/launch/assets/console/` resized with
`sips -Z 1600 <src> --out public/console/<name>.png` (1600×1000 PNG; JPEG smears UI text).

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
`headquarters/marketing/launch/refarch-neocloud.md` — and applied site-wide 2026-10-18.)

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
- **Restate is named where the engine is described** (Eron, 2026-10-18: "we should be proud to be
  using Restate"; this reversed the earlier never-name rule). `/engine/` carries a paragraph in
  Restate's own words (from docs.restate.dev), linked to restate.dev, with an attribution line beside
  the NVIDIA note, and the engine rows of `/compatibility/` ("Where Turf is ahead") name it;
  `/telemetry/` and `install.sh` name restate-server as before. Home and the use-case cards keep
  capability framing ("the cloud API is the ceiling", "thousands of resources per stack", "durable
  runs") and link `/engine/`. Internal names (RocksDB, HCP, virtual objects, partition processors)
  stay out; "journal" only as Restate itself describes durable execution. Nominative use only: no
  Restate logo, no implied endorsement.
- **Rounds, approval points and turf actions are the 1.0 vocabulary.** Say "round", never
  "phase"; the engine applies the approved plan, and the agent (and the user) intervene at approval
  points and at turf actions. Never "effect", "one effect at a time", `apply_all` or `effect_apply`:
  those described the pre-1.0 engine. Plots (`.tfplot.hcl`, `declare_*`, `config_promote`) were
  retired 2026-10-04: the agent writes ordinary `.tf` files. `turf_confirm` is gone: a question for
  the user is a `turf_action` whose prompt says to ask.
- **"Drop-in replacement" never leads** (de-emphasized 2026-08-25; greenfield-first). Compatibility
  is a supporting message: say "Terraform-compatible" or "standard Terraform". The provenance line
  ("independent product built on the OpenTofu framework") stays. **Never imply a migration from
  Terraform** (Eron, 2026-10-21): the reader is more likely coming from a console or a GitOps
  controller, so no "keep what you run", "your existing configurations", "estate" or "brownfield";
  say "start anywhere", "from the console to configuration" (the agent writes the HCL, `import`
  brings what exists under management). **"Sync" is the word for Helm**: every `helm_release` is a
  true Helm release, installed and upgraded through Helm itself, Helm hooks included, visible to
  `helm list`; a GitOps controller is never named.
- **"Approval point", never "gate"**, on home and `/use-cases/` since 2026-10-20 (the launch plan's
  rule; the older demo pages still say "gate"). **"Hook" is allowed again since 2026-10-21** (Eron
  retired the no-hook rule: "Resource lifecycle hooks." heads the actions band; Helm hooks are Helm's
  term). **"TACO" appears nowhere new**: the platform story is "your ops environment" — git repos,
  registries, centralized secrets, centralized policy, state in your backend — with Scalr, Spacelift,
  Artifactory, GitHub and GitLab named nominatively as options, under the marks note at the foot of
  `/use-cases/`. **Scale-out copy carries no benchmark, multiple or wall-clock figure**: say refresh,
  plan and apply fan out per resource and the cloud API, not the tool, is the ceiling; more engine
  nodes and per-provider flow control are `coming soon` (not in 1.0: the engine is one process with
  unbounded fan-out and one provider instance per region, account or alias).

**Tone.** No lean-startup vocabulary in public copy — in particular avoid "pain" / "pain point". Do not
imply existing customers, pilots, partners, or a team the company doesn't have: seeking pilot users
is fine, naming one is not. Since 2026-10-14 the launch is Turf 1.0, "available now": never "beta",
"alpha", "design partner", "evaluation license", "on request" or "waitlist" in copy, and the license
terms are those of `headquarters/marketing/licensing.md` (launch plan §4). Page `<title>`s are
Turf-leading (`Turf — …`).

**Locked messaging.** The hero headline is "**One tool, from metal to workload, at fleet scale.**"
(Eron's line, adopted 2026-10-20 with the home redesign as "One plan, …" and changed to "One tool" on
2026-10-21: a convergence is a series of plans from one configuration, so "one plan" misled; it superseded "The infrastructure engine
built for AI agents." of 2026-08-25, which the org profile and the paper's back page still carry
until they are re-done, and before that "Control your infrastructure AI with Terraform plans."). The
eyebrow is "A new infrastructure-as-code engine · built on OpenTofu" and the lede opens "Turf™ is a
new engine for infrastructure as code". The rotating headline phrase is retired. Home draws the line
the redesign exists for — not an automation platform over Terraform, not an agent wrapper, a new
engine under both, headed "Not a layer over Terraform. A new engine, with superpowers." (Eron,
2026-10-21; `components/WhyEngine.astro`: most platforms and agent tools shell out to
terraform or tofu, Turf replaces that tool with a durable, scale-out, interactive engine; the engine
map and run timeline figures) — without
naming a competitor. The five home cards
are the five **use cases**, factored by the job (GPU clouds · managed services on Kubernetes fleets ·
products that install themselves · your ops environment, Turf's engine · the ultimate infrastructure
agent), each with a Day 1 and a Day 2 on `/use-cases/`; the **five positioning pillars** of
`headquarters/marketing/use-cases.md` remain the message set behind them, and that touchstone doc
(messages, audiences, proof points, approved phrases, what not to say) is where any copy round
starts. Treat the headline as fixed unless the user reopens it.

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
  use cases, or the headline change. `public/logo.png` exists only as `Organization.logo` for JSON-LD;
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
  download button is the Scarf link with `?src=refarch-page`; the home banner linked the page until
  the 1.0 release, and the Datacenter card, the footer and `/engine/` link it.
  `public/papers/turf-neocloud-reference-architecture-cover.jpg` is page 1 of the PDF
  (`qlmanage -t -s 1600` on the PDF, `sips -Z 960`, then JPEG at quality 82); re-render it when the
  cover changes.
- There is no mobile hamburger menu — below 860px `.nav-links a:not(.btn)` is hidden and only the CTA
  shows. Adding a nav link means it's desktop-only unless you also add it to the footer sitemap
  (Use cases is in the nav, the footer's Product column and the hero's CTA row).

## Content provenance

`pages/compatibility.astro` was rewritten for 1.0 on 2026-10-18: the strengths table first ("Where
Turf is ahead": durable runs, encryption at rest, OpenTelemetry, provider calls that scale out,
Terraform actions with overlays, turf actions, multi-round convergence — Eron's list, in that
spirit), then the three-way matrix. Its sources, in order: turf-engine's refusal list
(`turf-engine/engine/tier2.go`, `refusedConstructs`); the deployment and authoring skills' reference
files as the 1.0 server ships them (`doof/internal/skills/content/{deployment,authoring}/references/`:
divergences, deferrals, imports, workspaces, lifecycle, actions, variables, providers, data sources);
the internal conformance report `doof/docs/development/analysis/language-feature-conformance.md`
(its 2026-10-08 "v1" entry; rows it did not re-verify are historical); the rc.1 acceptance pass
(`headquarters/research/rc1-acceptance-2026-10-17.md`); and Restate's docs for the engine rows. The
baselines are Terraform 1.16.x (October 2026) and OpenTofu 1.13.x (September 2026), re-grounded
against the changelogs (Terraform has no `-exclude`; OpenTofu has no action blocks): re-ground them
before each publish. `-target`/`-exclude` are divergences by design, not "coming soon"; the
encryption row carries the honest clause that state encryption protects the backend's statefile, not
the engine's store. When syncing from the report: strip `FU-####` ids, `internal/…​.go:NNN` code
anchors, and design-doc paths; the "Known divergences" section was removed on purpose (inaccurate
and off-message) — don't reinstate it.

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
`/get-started/` is the download page (launch plan D22, closed 2026-10-18; there is no `/download/`
route, and posts and listings link `/get-started/`), so it prints that document's announcement
line ("Turf is free for noncommercial use under PolyForm Noncommercial 1.0.0. Companies can evaluate
Turf free for 60 days and license it for production at turf.build/licensing.") beside the install,
above the telemetry sentence: a download surface carries both (launch plan §4.2).

`pages/engine.astro` is the Turf 1.0 announcement (launch plan §3, §8). Its sources, in order: the
launch paragraph and the two-layer frame from `headquarters/marketing/launch-plan.md` §1 and §3;
the ten engine points and the three-ecosystems chapter of *Metal to Tokens* (`refarch-neocloud.md`,
"The Turf engine" and chapter 9, whose counts are the paper's, dated October 2026); the 1.0
acceptance pass (`headquarters/research/rc1-acceptance-2026-10-17.md`) for "What's in 1.0"; and
`licensing.md`'s announcement line, byte for byte, under the CTAs. The headline is launch plan D2's
first candidate ("Turf 1.0 is available now."). The NVIDIA quotation is AICR's README ("Not a cluster
provisioner or lifecycle management system"), so the page carries the NVIDIA marks note. Its
`TechArticle`'s `datePublished` is 2026-10-18, the day the release and the page went live. Home's
`SoftwareApplication` carries `softwareVersion` and `releaseNotes` → `/engine/` from the release on.

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

`pages/demo.astro` mirrors the kind-crd example at `turfbuild/turf-examples`; the round labels and
changes shown in the HCL diagram are exactly what `turf up` computes, so they must be re-checked
against a real run rather than hand-authored. Demo videos live in `public/demos/` as webm+mp4 pairs
with poster PNGs. Both demo pages' recordings are pre-1.0 takes (kind-crd 2026-08-06, Scalr
2026-08-10, from `headquarters/recordings/`); the pages were moved to 1.0 vocabulary on 2026-10-18
and `/demo/scalr/` dropped its backend still, which showed the retired plot flow. Re-record both on
1.0 with `headquarters/recordings/render.sh` (the Scalr `setup` still pins OpenTofu 1.12.5 and must
be unpinned first), then re-derive each `VideoObject`'s `uploadDate` and `duration`.

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
