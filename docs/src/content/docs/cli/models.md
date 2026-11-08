---
title: Model providers
description: "Pick the model the turf CLI runs on: a hosted provider's key, a local model in Docker Model Runner or Ollama, an OpenAI-compatible endpoint, or turf.yaml."
sidebar:
  order: 8
---

The Turf™ CLI runs on any model provider that Docker's [docker-agent](https://docs.docker.com/ai/docker-agent/)
runtime supports. Pick one with `--model provider/model` (or `TURF_MODEL`), or pin a default in
[`turf.yaml`](#the-turfyaml-file). Your own agent needs none of this: it brings its own model.

```sh
turf --model anthropic/claude-sonnet-5 chat
```

The default is `auto`: turf picks the first provider whose credentials are set, and falls back to a
keyless local model, so it runs out of the box. Docker's
[providers overview](https://docs.docker.com/ai/docker-agent/providers/overview/) lists every provider
and its exact configuration.

:::caution[turf needs a tool-calling model]
Turf does everything through tools, so the model must support tool (function) calling. The hosted
models below all do. For a local model, pick a tool-capable one: a model without it fails with
`does not support tools`.
:::

## Run a model locally

A local model runs on your own machine: no API key, no cost, and your infrastructure prompts stay off
third-party APIs. It needs two things a hosted model does not: a **tool-capable** model, and a
**context window large enough for turf's prompt**.

turf's prompt is about 27k tokens before you type anything: two dozen infrastructure tools and their
workflow instructions go in every request. Docker Model Runner's default window is far smaller, so an
unconfigured local model rejects turf's first message with `exceeds the available context size`. Set
`context_size` and it works.

### Docker Model Runner

Docker Model Runner comes with Docker Desktop. Pull the model, then declare it in a `turf.yaml`:

```sh
docker model pull ai/qwen3     # once: fetch the model
```

```yaml title="~/.turf/turf.yaml (global) or <project>/.turf/turf.yaml"
model: local

models:
  local:
    provider: dmr
    model: ai/qwen3
    provider_opts:
      # turf's own prompt is ~27k tokens, so Model Runner's default window
      # rejects the first request. 64k leaves working room for plan and state
      # tool results. Lower it if the model won't fit in memory: the engine
      # reserves cache for the whole window up front, so memory use scales
      # with this number.
      context_size: 65536
```

Then run `turf chat`. The file is required: `context_size` is a per-model setting, so
`--model dmr/ai/qwen3` on its own cannot carry it and falls back to the runner's default window. turf
finds the local Model Runner itself; set `MODEL_RUNNER_HOST` to point at a remote one. See Docker's
[Model Runner guide](https://docs.docker.com/ai/docker-agent/dmr/).

### Ollama

If you already run Ollama:

```sh
turf --model ollama/llama3.2   # defaults to http://localhost:11434
```

Ollama has the same context problem with a different knob: `provider_opts` does not reach it. Size its
window with `OLLAMA_CONTEXT_LENGTH` (or `num_ctx` in a Modelfile) before starting the Ollama server.

### Which local model

Pick a tool-capable model: Docker Model Runner's `ai/qwen3`, or on Ollama one of `llama3.1` or
`llama3.2`, `qwen2.5`, or the `mistral` family. Older or smaller builds (plain `llama3`, tiny 1B
GGUFs) often lack tool support and fail with `does not support tools`.

## Hosted providers

Export the provider's API key, then select the model. A representative set:

| `--model` prefix | Example `--model` | API key variable |
|---|---|---|
| `anthropic` | `anthropic/claude-sonnet-4-6` | `ANTHROPIC_API_KEY` |
| `openai` | `openai/gpt-5` | `OPENAI_API_KEY` |
| `google` | `google/gemini-pro-latest` | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |
| `mistral` | `mistral/mistral-large-latest` | `MISTRAL_API_KEY` |
| `groq` | `groq/llama-3.3-70b-versatile` | `GROQ_API_KEY` |
| `deepseek` | `deepseek/deepseek-chat` | `DEEPSEEK_API_KEY` |
| `xai` | `xai/grok-4` | `XAI_API_KEY` |
| `amazon-bedrock` | `amazon-bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0` | standard AWS credentials |

turf inherits docker-agent's full provider list, Azure OpenAI and GitHub Copilot included. See the
[providers overview](https://docs.docker.com/ai/docker-agent/providers/overview/) for every option.

## OpenAI-compatible endpoints

For any OpenAI-compatible server (vLLM, LM Studio, an internal gateway), use the `openai` provider and
override the endpoint with `--base-url` (or `TURF_MODEL_BASE_URL`):

```sh
turf --model openai/my-model --base-url http://localhost:8000/v1
```

## The turf.yaml file

A `turf.yaml` pins a model configuration beyond the flags. turf reads it from two places, the project
file overriding the global one:

- `~/.turf/turf.yaml`: per user, global (`TURF_HOME` moves the home directory);
- `<project>/.turf/turf.yaml`: versioned alongside your infrastructure configuration.

The model is chosen in this order: `--model` or `TURF_MODEL`, then `turf.yaml`'s `model:`, then
`auto`. A minimal file:

```yaml title=".turf/turf.yaml"
# Default selector: a named model below, an inline provider/model, or "auto".
model: smart

models:
  # Try each candidate in order; pick the first whose credentials are set. A
  # candidate is an inline provider/model OR the name of another entry here,
  # which is how the local fallback below keeps its provider_opts.
  smart:
    first_available:
      - anthropic/claude-sonnet-5
      - openai/gpt-4o
      - local                 # keyless local fallback (defined below)
  # Docker Model Runner. context_size is required for local models: turf's own
  # prompt is ~27k tokens and the runner's default window is far smaller.
  local:
    provider: dmr
    model: ai/qwen3
    provider_opts:
      context_size: 65536
  # A named model that targets a custom provider (defined below).
  house:
    provider: myhouse
    model: my-model

# Custom providers, referenced by models by name, such as an internal
# OpenAI-compatible gateway. Credentials are read from the named env var.
providers:
  myhouse:
    provider: openai
    base_url: https://gateway.internal/v1
    token_key: MY_HOUSE_KEY
```

The `models:` and `providers:` values follow docker-agent's model and provider schema, so per-model
tuning fields (`temperature`, `max_tokens`, …) and a top-level `models_gateway:` work here too. The
same file carries the [`branding:`](/docs/cli/theming/#co-branding) section. For a complete project,
see the [CLI configuration example](https://github.com/turfbuild/turf-examples/tree/main/integrations/turf-cli).
