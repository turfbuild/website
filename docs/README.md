# turf.build/docs

The Turf documentation: a [Starlight](https://starlight.astro.build) site served at `turf.build/docs/`.
It is its own Astro project (this directory, its own `package.json`), built after the marketing site by
the root `npm run build` and copied into `dist/docs` by `scripts/merge-docs.mjs`, so one GitHub Pages
deploy serves both. The plan it follows is `headquarters/marketing/docs-plan.md`.

```sh
npm install          # from the repo root; postinstall installs this directory too
npm run dev:docs     # http://localhost:4321/docs/
npm --prefix docs run build
npm --prefix docs run check
npm --prefix docs run generate   # the MCP reference, from a turf-mcp-server binary (see below)
```

## Layout

```
src/content/docs/
  index.mdx            the landing page (template: splash)
  start/               Start here: what Turf is, install, connect, first run, cluster pointer
  concepts/            Overview, rounds and deferrals, approval, turf actions, engine and console, safety rules
  using/               one page per task: up, destroy, plan-and-apply, refresh, import, invoke, …
  environment/         provider environment and credentials (its own chapter)
  authoring/           writing configurations with an agent; differences from Terraform
  cli/                 the Turf CLI
  cluster/             running Turf in a cluster; kagent as the closing example
  reference/           the MCP reference: server, result shape, tools/ (generated), prompts, resources,
                       skills/ (generated), instructions (generated), slash commands
  releases/            release notes, one page per release
src/components/        Conversation, User, Agent, ToolResult, Still, Since; Footer and SiteTitle overrides
src/styles/docs.css    the brand: turf.build's tokens mapped onto Starlight's --sl-color-*
public/stills/         screenshots, PNG, 1600 wide
scripts/               generate-reference.mjs
```

The sidebar is defined in `astro.config.mjs`: every group autogenerates from its directory, so a page's
place comes from its frontmatter. The MCP reference group lists its pages explicitly; add a new one there.

## Writing a page

Frontmatter:

```yaml
---
title: Deploy or update with up          # the sidebar label and the h1; Turf-leading titles are for <title> only
description: One plain sentence, 140–158 characters, no markdown; it is the search snippet.
sidebar:
  order: 1                               # position within the group
  badge: { text: 'Since 1.4', variant: 'note' }   # optional: a group-level "arrived after 1.0"
---
```

Pages are `.mdx` when they use a component, `.md` otherwise. Import components from
`../../../components/<Name>.astro` (three levels up from a page in a group directory).

- **Links** to other docs pages are absolute and carry the base and a trailing slash:
  `/docs/using/up/`. Links to the marketing site are full URLs: `https://turf.build/compatibility/`.
  Anchors are `#kebab-case` of the heading.
- **Code blocks** name a language (`sh`, `hcl`, `json`, `yaml`, `text`). Starlight renders them with
  Expressive Code: use `title="main.tf"` for a filename and `// [!code highlight]`-style markers sparingly.
  A shell block shows commands without a prompt and comments with `#`.
- **Inline `{` `}` and `<`** in MDX prose must be escaped or wrapped in backticks: ``{ var: { region } }``
  is fine inside code; bare braces in a sentence break the build.
- **Badges.** `<Since v="1.4" />` at the first mention of a feature that arrived after 1.0;
  `<Since soon />` for a capability not yet shipped. Starlight's own `Badge`, `Aside`, `Tabs`,
  `TabItem`, `Steps`, `Card`, `LinkCard` come from `@astrojs/starlight/components`.
- **Agent first, CLI second.** A task page shows the task in the user's agent (Claude Code is the worked
  example), then the `turf` CLI in a second tab: `<Tabs><TabItem label="In your agent">…</TabItem>
  <TabItem label="Turf CLI">…</TabItem></Tabs>`.
- **A conversation opens a task page.** `<Conversation>` with `<User>`, `<Agent calls={['up → awaiting_plan']}>`
  and optional `<ToolResult tool="plan" outcome="awaiting_approval">` children whose body is a ```text
  fenced code block (bare braces in a slot are MDX expressions and break the build). Conversations are
  illustrative: written to show the shape of a task (the ask, the calls, the approval, the result), not
  transcripts, and they carry no provenance caption. Keep them short: three to five turns.
- **Stills.** `<Still id="runs" src="stills/console-runs.png" alt="…" caption="…" />`; one `id` per
  still on a page; PNG at 1600 wide in `public/stills/`.

## Voice

The marketing site's rules (`../CLAUDE.md`, "Copy and voice rules") apply; the ones a docs page meets most:

- Turf™, Terraform®, OpenTofu™, Kubernetes®, Helm® carry their mark **once per page**, at the first
  prominent use in body text; never in headings, code or titles. The footer carries the attribution.
- Say **round**, **plan gate**, **approval point**, **turf action**; never phase, gate (alone) or effect.
  Say "OpenTofu framework", never "OpenTofu engine". Say "module registry", never "the Terraform Registry".
- `cd path/to/config && turf up`, never `turf up path`.
- No rollback or undo promises. Unshipped capabilities are "coming soon", with the badge.
- Short sentences, concrete nouns, one idea each. Lead a page with what the reader can do, then how it
  works, then the tables. A reader who stops after the first screen should know the shape of the task.
- Facts come from the sources the plan names (the skill files in turf-mcp-server, the turf README, the
  turf-kagent README). Nothing is invented: a value, flag or behaviour that cannot be found in a source
  is left out, or marked as a gap in the pull request.

## The generated reference

`scripts/generate-reference.mjs` starts a `turf-mcp-server` (`TURF_MCP_SERVER=/path/to/binary`, default
the one on PATH) over stdio and writes `reference/tools/*.md`, `reference/prompts.md`,
`reference/resources.md`, `reference/skills/*.md` and `reference/instructions.md` from `tools/list`,
`prompts/list`, `resources/templates/list`, the three skill tools, `read_skill_file` and the
`initialize` result. Each page carries a generated banner and the server version. Run it once per
release; the diff is the release's reference change. The output is committed; the build never needs
a turf binary.
