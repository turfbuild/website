---
title: Slash commands in Claude Code
description: "Turf's three prompts in Claude Code: /turf:guide, /turf:up and /turf:destroy, their arguments in order, and how Claude Code fills them one word at a time."
---

In Claude Code, the server's three [prompts](/docs/reference/prompts/) are slash commands:
`/turf:guide`, `/turf:up` and `/turf:destroy`. This page shows what each one takes and how Claude Code
fills its arguments. In other clients, ask in words.

```text
/turf:guide
/turf:up path/to/config
/turf:destroy path/to/config
```

The prefix is the name the server was registered under: `turf`, from `--name turf` or
`claude mcp add turf` (see [Connect your agent](/docs/start/connect/)). Claude Code also runs them as
`/mcp__turf__guide`, `/mcp__turf__up` and `/mcp__turf__destroy`, but does not list that form.

## The commands

| Command | Arguments, in order | What it does |
|---|---|---|
| `/turf:guide` | `topic` | A hands-on walkthrough of Turf™ on real examples from [turf-examples](https://github.com/turfbuild/turf-examples). |
| `/turf:up` | `config_path`, `instructions` | Deploys or updates the infrastructure a configuration directory declares. |
| `/turf:destroy` | `config_path`, `instructions` | Destroys everything in a workspace. |

Every argument is optional:

- **`config_path`** is the configuration directory. Without one, the agent asks which directory.
- **`instructions`** steer the run, such as which resource to replace or which module to touch. They are
  honoured within the normal plan and approval flow and never bypass approval, or a destroy's
  confirmation.
- **`topic`** opens a journey directly: deploy AICR, day-2 maintenance, installer, promotion, TACO or
  guardrails. Without one, the guide offers the menu. The agent matches a topic to the journey that fits
  best, so `/turf:guide maintenance` opens day 2.

`/turf:up` and `/turf:destroy` run the same flow as asking in words: a plan gate and an approval point
every round. The agent approves only a low-risk plan itself, asks you about any other, and always asks
about a destroy plan. See [Approval](/docs/concepts/approval/).

## One word per argument

Claude Code fills a prompt's arguments one typed word each, in the order the server declares them. A
word past the last argument is dropped. So:

- **The path has no spaces.** `/turf:up ./infra` works; a path with a space in it is split into two
  arguments.
- **`instructions` gets one word.** `/turf:up ./infra staging` passes `staging`. Anything longer, say in
  the conversation instead, as you would in any other client.
- **`config_path` comes first.** The first word is always the directory; a second word, if any, is
  `instructions`.

## Tiers

`/turf:up` and `/turf:destroy` appear only when the server runs at the `plan` or `full`
[tier](/docs/reference/server/#tiers). At `read` and `apply`, Claude Code lists `/turf:guide` alone.
At `plan`, every run ends with a planfile instead of an apply.

## In other clients

In a client without slash commands, ask in words: "deploy the configuration in ./infra with Turf". The
agent follows the same flow, guided by the [server instructions](/docs/reference/instructions/) and the
[deployment skill](/docs/reference/skills/deployment/).
