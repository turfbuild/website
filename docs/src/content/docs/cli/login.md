---
title: Log in to a host
description: "turf login saves an API token for a private registry or a TFE-compatible backend where tofu and terraform read it too; turf logout removes it again."
sidebar:
  order: 5
---

`turf login <hostname>` gets an API token for a Terraform®-compatible host, such as a private module
registry or a TFE-compatible backend (HCP Terraform, Scalr), and saves it. `turf logout <hostname>`
removes it again. Like `tofu login`, both need an explicit hostname; neither guesses a default.

```sh
turf login app.terraform.io
turf logout app.terraform.io
```

## Where the token goes

The token is written to `credentials.tfrc.json` in your OpenTofu™ and Terraform CLI configuration
directory, in the format those tools write, so a co-installed `tofu` or `terraform` reads exactly what
Turf™ stores, and the other way round.

| Platform | Path |
|---|---|
| macOS, Linux | `~/.terraform.d/credentials.tfrc.json` |
| Linux, a fresh install with `XDG_CONFIG_HOME` set and no `~/.terraform.d` | `$XDG_CONFIG_HOME/opentofu/credentials.tfrc.json` |
| Windows | `%APPDATA%\terraform.d\credentials.tfrc.json` |

The file is written with mode `0600`. Settings already in it (`plugin_cache_dir`,
`provider_installation`, other hosts) are kept.

## Which process reads it

Turf uses the token for its own requests to the host: `remote`-protocol state backends (HCP Terraform,
Scalr, TFE) and the provider registry. The MCP server and the engine both read the credentials file,
so one `turf login` covers Turf and a co-installed `tofu` or `terraform` alike.

A `TF_TOKEN_<hostname>` variable (dots as underscores) works only in the environment of the process
that needs it: the server's for the `remote` backend and `init`'s installs, the engine's for the
installs a plan makes. Set it in both, or use the credentials file. See
[State backend, registries and mirrors](/docs/environment/registries-and-mirrors/).

## How you sign in

Most hosts, HCP Terraform and Scalr among them, do not implement the OAuth login protocol. For those,
`turf login` opens the host's user-token page and reads back the token you paste. A host that
advertises a `login.v1` service gets a full OAuth 2.0 authorization-code flow with PKCE instead.
Either way, turf shows you where the token will be stored and asks before writing it.

## In CI

Pipe the token in with `--token-stdin`:

```sh
echo "$TFE_TOKEN" | turf login --token-stdin tfe.example.com
```

Prefer a pipe to a herestring (`<<<`), which some shells write to a temporary file. Without
`--token-stdin`, `turf login` refuses to run with stdin redirected, rather than wait on a prompt nobody
can answer.

## Precedence

When a host is configured more than once, OpenTofu's order applies: a `TF_TOKEN_<hostname>`
environment variable wins over the credentials file, which wins over a credentials helper.
`turf login` warns when the token it is about to write would be shadowed by such a variable, and
`turf logout` warns when one will keep authenticating you after the stored token is gone.

## Limits

- turf does not detect a `credentials` block written by hand in `.terraformrc` or `.tofurc`. Such a
  block keeps winning over the file turf writes, silently.
- turf does not support credentials helpers.
- `turf logout` forgets the token locally only. It does not revoke it on the host: if it has leaked,
  revoke it there.
