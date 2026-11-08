---
title: Scripting with exec
description: "turf exec runs one plain-language request without the TUI, for scripts, CI jobs and other agents; --json streams events, and a failed run exits non-zero."
sidebar:
  order: 4
---

`turf exec` runs a single plain-language request without the TUI and streams the run to stdout. It is
how you drive Turf™ from a script, a CI job or another agent: the same model and tools as
[`turf chat`](/docs/cli/chat/), headless.

```sh
# A message argument: quoting is optional, the words are joined into one request
turf exec create a random_pet named demo
turf exec "create a random_pet named demo"

# Use -- for a message that begins with a dash
turf exec -- --dry-run first, then apply

# Read the request from stdin
echo "what workspaces exist?" | turf exec
turf exec - < request.txt
```

With a terminal and no message, `turf exec` starts a plain readline prompt loop instead. Set the model
with `--model` ([Model providers](/docs/cli/models/)), and the directory with `-C`.

## Exit status

The process exits non-zero if the run fails, so `exec` composes with ordinary shell error handling:
`set -e`, `&&`, CI steps.

## --json: a machine-readable event stream

With `--json`, turf prints one JSON object per line for every runtime event (agent text, tool calls,
tool results, warnings, errors) instead of formatted text. Model prose changes from run to run; match
on structure instead, such as which tools ran and whether an error occurred.

```sh
# Which Turf tools did the run call?
turf exec --json "create a random_pet" | jq -r 'select(.type=="tool_call") | .tool_call.function.name'

# A failed run exits non-zero; its error goes to stderr, not into the event stream
turf exec --json "reconcile the stack" > events.jsonl || echo "run failed" >&2
```

`--hide-tool-calls` goes the other way: it prints only the agent's prose.

## --yes: unattended runs

`exec` is non-interactive, so nobody can answer the agent's approval questions. Without `--yes` they
are declined: anything that needs your yes, such as a destroy, a replace, an import or an invoke, is
not applied and stays waiting at its approval point, where a later interactive `turf` can pick it up.
The agent still approves a low-risk plan itself (creates and in-place updates only), as it does at a
terminal.

`--yes` (alias `--auto-approve`) answers those questions yes, and approves any other tool call that
would ask on stdin, so the run goes ahead with no one at the keyboard. Nothing is approved up front on
the server's side: the agent still plans each round and approves each plan by its digest, so a `--yes`
destroy is one the agent saw the plan of. Turf's own tools never ask for permission.

The same rule holds for `turf up` and `turf destroy` run without a terminal
([Up and destroy](/docs/cli/up-and-destroy/#unattended-runs-yes)).

## Resume a session

`exec` takes `--session <id|-N>` and `--continue` (`-c`), as `turf chat` does, so a script can carry
one conversation across several requests ([Sessions](/docs/cli/chat/#sessions)).

## Runs with no cloud

`exec` still launches `turf-mcp-server`, so the server must be on `PATH`
([Overview](/docs/cli/overview/#install)). For repeatable runs with no cloud credentials or cost, point
it at HCL that uses OpenTofu™ providers that need no credentials: `null`, `local`, `random`, `tls`.
