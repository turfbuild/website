---
title: Theming and co-branding
description: "Pick one of five terrain themes for the turf TUI or write your own, and give a distributed turf your own banner, welcome text and instructions with branding."
sidebar:
  order: 10
---

The Turf™ CLI ships five terrain themes, takes custom themes from `~/.turf/themes`, and lets a
distributor set its own look and voice in `turf.yaml` without forking it.

## Terrain themes

The five built-in themes are a play on the name: the same astroturf, imagined in a different terrain,
each palette drawn from that place's natural objects. A terrain tints the HCL syntax colors and the
create, destroy and change status colors, but they keep their meaning (create stays green, destroy
red, change amber), so a plan stays legible.

| Theme | Terrain | Palette |
|---|---|---|
| `meadow` | real, natural turf | grass and loam canvas, wildflower buttercup and goldenrod, thistle and lavender ink |
| `stadium` | football-field astroturf, the default | vivid turf, white chalk yard-lines, pigskin, flag red |
| `sonora` | Arizona xeriscape | adobe, sandstone, saguaro green, turquoise, sunset coral |
| `lunar` | astroturf on the moon | grey regolith, black sky, Earthrise blue, astro-green |
| `surf` | turf underwater | seagrass, deep teal ocean, bioluminescent cyan, coral, sea-urchin purple |

The default is `stadium`. The agent runtime's own built-in themes, and the legacy `calm-roots`, stay
selectable in the theme picker: `/settings`, then Appearance, then Theme, in `turf chat`. There is no
`/theme` command. Themes are loaded from and saved to turf's own home, `~/.turf` (`TURF_HOME` moves
it), so turf never reads or writes `~/.cagent`.

To preview a theme without changing your saved choice, launch with `--theme` (or `TURF_THEME`):

```sh
turf --theme tokyo-night chat
```

## Custom themes

Drop a YAML file at `~/.turf/themes/<name>.yaml` and pick it in the theme picker. A partial file is
merged onto the built-in default, so you only give the colors you want to change. Edits reload while
the picker is open, and your choice persists across restarts.

```yaml title="~/.turf/themes/my-brand.yaml"
version: 1
name: "My Brand"
colors:
  text_primary: "#C0C0C0"
markdown:
  heading: "#7AA2F7"
  link: "#7AA2F7"
```

## Co-branding

A distributor can give turf its own look and voice, without forking it, with a `branding:` section in
[`turf.yaml`](/docs/cli/models/#the-turfyaml-file). It merges from the same two places, so a brand can
be set once per machine (`~/.turf/turf.yaml`) or per project (`<project>/.turf/turf.yaml`), and a
project file can override a single key while inheriting the rest.

```yaml title=".turf/turf.yaml"
branding:
  # Default theme: a theme *ref*, not a path. One of turf's terrain themes, or
  # your own dropped at ~/.turf/themes/<name>.yaml (see Theming).
  theme: surf

  # Welcome banner for the lean TUI, as a path relative to this turf.yaml.
  # Plain text is fine: each line is drawn in the theme's accent color.
  banner: acme-banner.txt

  # Replaces turf's built-in chat welcome text.
  welcome_message: |
    Welcome to Acme Cloud — infrastructure management with governance built in.

  # Appended to turf's persona as extra standing guidance.
  additional_instructions: |
    Evaluate the plan against the workspace's policy set before asking the
    user to approve it.
```

| Key | What it does |
|---|---|
| `theme` | The default theme, by name: a terrain theme or one in `~/.turf/themes` |
| `banner` | A welcome banner for the lean TUI, as a path relative to the `turf.yaml`; each line is drawn in the theme's accent color |
| `welcome_message` | Replaces turf's built-in chat welcome text |
| `additional_instructions` | Appended to turf's persona as extra standing guidance |

### What branding does not change

Branding is look and voice only: it does not rename turf. There is no `name` key. The binary, the TUI
status bar and the agent badge all still say `turf`, so a co-branded turf is still recognizably turf.
The tool namespace stays `turf_*`: the timeline renderers, the `/tools` grouping and the pre-approval
allow-list depend on it. No safeguard is relaxed either: the pre-approved tool list, the mutation
confirmations and the filesystem sandbox are all in code.

Two more things to know:

- `theme:` sets the default only. A theme saved in the picker and `--theme` both still win, so a user
  keeps control of their own look.
- `additional_instructions` is prompt content from a config file, and it can steer the agent. Treat a
  `turf.yaml` from an untrusted source with the same care as any script you would run.

A misconfigured brand degrades rather than fails: an unreadable banner or theme falls back to turf's
own, with a warning.

For worked examples, see the
[integrations](https://github.com/turfbuild/turf-examples/tree/main/integrations) in the examples repo.
