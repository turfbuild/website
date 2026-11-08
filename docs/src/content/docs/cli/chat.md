---
title: Chat
description: "turf chat opens the Turf agent in your terminal, with the lean TUI, saved sessions you can resume, persistent memory and /guide walkthroughs to start with."
sidebar:
  order: 2
---

`turf chat` opens the Turf™ agent in your terminal. Type what you want in plain words, to create,
update or inspect resources, and the agent carries it out through the MCP server and the engine.
`turf` with no command opens the same session.

```sh
turf chat
turf chat --lean                              # the lean TUI, in your scrollback
turf --model anthropic/claude-sonnet-5 chat   # a specific model
```

The agent needs a model: see [Model providers](/docs/cli/models/).

## Start with a walkthrough

Type `/guide` in the session to see what Turf is for, on real examples from
[turf-examples](https://github.com/turfbuild/turf-examples): deploy the NVIDIA AI Cluster Runtime
(AICR) on a kind cluster, take a node through the day-2 maintenance runbook as Terraform® actions, a
product that installs itself, promotion across environments, your ops environment as the control
plane, and deploying with guardrails. Name one to go straight to it:

```text
/guide day 2
/guide guardrails
```

## The lean TUI

`--lean` (or `TURF_LEAN`) runs chat in the lean TUI: no sidebar, tabs or overlays, and it renders to
your terminal's scrollback. `turf up` and `turf destroy` on a terminal always use it. A distributor's
welcome banner shows here ([Co-branding](/docs/cli/theming/#co-branding)).

## Sessions

turf saves each session in `.turf/sessions.db` in the working directory, so you can pick one up
again:

```sh
turf chat --continue        # the most recent session (-c; the same as --session -1)
turf chat --session <id>    # a session by its ID
turf chat --session -1      # or by relative offset: -1 is the most recent
```

`--session-db` (or `TURF_SESSION_DB`) keeps the database somewhere else. `--no-session` turns saving
and resuming off. `turf exec` resumes sessions the same way; `turf up` and `turf destroy` do not.

## Memory

The agent keeps a persistent memory in `.turf/memory.db` in the working directory. `--memory-path`
moves it, and `--no-memory` turns it off.

## In the session

| Type | To |
|---|---|
| `/guide [topic]` | Start a use-case walkthrough |
| `/tools` | See the agent's tools, with Turf's own grouped by what they do |
| `/settings`, then Appearance, then Theme | Pick a theme ([Theming](/docs/cli/theming/)); there is no `/theme` command |
| Ctrl+K, then Report Bug | File a bug |

## Files the agent can reach

The agent's file tools work in the working directory. `--allow-path` adds a directory they may read
and write, auto-approved. Repeat the flag for more, or list them in `TURF_ALLOW_PATH`, separated as
in `PATH`. A relative path resolves against the working directory, so prefer absolute ones.

```sh
turf chat --allow-path /srv/shared-modules
```

## Work in a throwaway worktree

`--worktree` runs turf in a fresh git worktree of the working directory, on a throwaway branch, so the
HCL the agent writes stays off your own branch. `--worktree=name` names it. `--worktree-base main`
branches it from that ref instead of `HEAD`; a remote-tracking ref is fetched first.

```sh
turf --worktree chat
turf --worktree=try-redis --worktree-base origin/main chat
```
