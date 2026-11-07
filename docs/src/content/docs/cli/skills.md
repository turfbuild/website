---
title: Skills
description: "Teach the turf CLI your own procedures with SKILL.md files in ~/.turf/skills or a project's .turf/skills, loaded when a request matches their description."
sidebar:
  order: 9
---

You can teach the Turf™ CLI your own procedures by dropping `SKILL.md` files where turf looks for
them. Each skill is a directory:

```text
~/.turf/skills/<name>/SKILL.md          # global: org best practices, migration playbooks
<project>/.turf/skills/<name>/SKILL.md  # project: versioned alongside your infrastructure configuration
```

Your skills add to the infrastructure workflows the agent already knows; they don't replace them.

## Where turf looks

turf scans only these two locations; `TURF_HOME` moves the global one. It never reads `~/.claude`,
`~/.codex` or `~/.agents`. A project skill overrides a global skill of the same name.

The project location is exactly `<cwd>/.turf/skills`. turf does not walk up the tree, so what loads is
predictable from where you launch it.

## Write a skill

A `SKILL.md` needs YAML frontmatter with at least `name` and `description`. The description is what
turf matches a request against. Keep the body lean and push detail into supporting files, which load
on demand:

```markdown title="~/.turf/skills/azure-migration/SKILL.md"
---
name: azure-migration
description: Adopt hand-built Azure resources into managed state. Use when the user says "adopt" or "import our existing".
# context: fork   # optional: run this skill as an isolated sub-agent
---

# Azure migration playbook

Adopt-then-reconcile; never create before importing.

1. Import each existing resource (ID formats: see references/import-ids.md).
2. Plan: an `adopt id=…` row with no change means clean adoption; `~` or `-/+` means drift to reconcile.
```

```text
~/.turf/skills/azure-migration/
  SKILL.md
  references/
    import-ids.md      # loaded on demand when the skill needs it
```

`context: fork` in the frontmatter runs the skill as an isolated sub-agent.

For a working project skill you can copy, see the
[CLI configuration example](https://github.com/turfbuild/turf-examples/tree/main/integrations/turf-cli).

These skills are the CLI's. An agent you connect to the MCP server gets Turf's own skills from the
server ([Skills and their references](/docs/reference/skills/deployment/)).
