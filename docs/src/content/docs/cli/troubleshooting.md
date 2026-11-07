---
title: Troubleshooting
description: "Fix the turf CLI when it won't start, when the server is missing or from another release, or when a local model has no tool support or too small a window."
sidebar:
  order: 11
---

Most Turf™ CLI problems are the model or the server: turf cannot reach a model, cannot find
`turf-mcp-server`, or runs a local model that is too small for its prompt. Find the message you see
below.

## turf won't start

**`could not start the model … API key … is required`**: turf could not reach a model. Set the key
for your provider, or switch to a keyless local model, which needs a `turf.yaml`, not just a `--model`
flag ([Run a model locally](/docs/cli/models/#run-a-model-locally)).

**`unknown provider …` or `invalid model format …`**: `--model` must be a named model from
`turf.yaml` or a `provider/model` reference, such as `anthropic/claude-sonnet-5` or
`google/gemini-pro-latest`. Check the prefix against Docker's
[providers overview](https://docs.docker.com/ai/docker-agent/providers/overview/).

**`turf-mcp-server not found on PATH`**: the CLI launches the server as a subprocess and must find
it. Install it and put it on `PATH`, or point at it
([Install](/docs/cli/overview/#install)):

```sh
export TURF_MCP_SERVER=/path/to/turf-mcp-server
```

**The server rejects turf's flags at startup**: the CLI and the server are from different releases.
`turf` starts the server with its own release's flags (`--deadline`), which an older
`turf-mcp-server` rejects. turf names the binary it ran; point `TURF_MCP_SERVER` at one from the same
release.

## The model does not support tools

```text
model failed: … does not support tools
```

turf does everything through tools, so the model must support tool (function) calling, and many local
models don't. Switch to a tool-capable model: Docker Model Runner's `ai/qwen3`, or on Ollama one of
`llama3.1` or `llama3.2`, `qwen2.5`, or `mistral`, rather than plain `llama3`. See
[Model providers](/docs/cli/models/#which-local-model).

## The context window is too small

```text
model failed: … exceeds the available context size
```

A local model is running with a context window smaller than turf's prompt. turf sends about 27k tokens
before you type anything (two dozen infrastructure tools and their workflow instructions), and Docker
Model Runner's default window is far smaller, so the first message is rejected.

Declare the model in a `turf.yaml` with a `context_size` that fits, then run `turf chat` with no
`--model` flag. The setting is per model, so `--model dmr/ai/qwen3` alone cannot carry it:

```yaml title=".turf/turf.yaml"
model: local
models:
  local:
    provider: dmr
    model: ai/qwen3
    provider_opts:
      context_size: 65536
```

On Ollama the same knob is `OLLAMA_CONTEXT_LENGTH`. See
[Run a model locally](/docs/cli/models/#run-a-model-locally).

## The machine bogs down while a local model runs

The inference engine reserves cache for the whole context window up front, so memory use scales with
`context_size`. A large window on a large model can exhaust RAM and push the machine into swap. Lower
`context_size` (32768 is the practical floor, given turf's prompt of about 27k tokens), or pick a
smaller model.

## Still stuck

- Run with `--debug` and read `~/.turf/turf.debug.log`; `--log-level debug --log-file server.log`
  captures the server's side ([Flags and environment](/docs/cli/flags-and-environment/#logging)).
- Report a bug from `turf chat` (Ctrl+K, then Report Bug) or on
  [GitHub Issues](https://github.com/turfbuild/turf/issues).
- Ask on [Discord](https://turf.build/discord/), or write to contact@turf.build. Security reports go
  privately to security@turf.build
  ([security policy](https://github.com/turfbuild/.github/blob/main/SECURITY.md)).
