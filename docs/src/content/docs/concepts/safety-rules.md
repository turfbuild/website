---
title: Safety rules
description: "The seven rules the Turf MCP server hands every agent at connection, in the user's terms: what the agent will and will not do with your plans, your files and your infrastructure."
sidebar:
  order: 6
---

When an agent connects, the server hands it a page of instructions before its first call. Seven of
those lines are rules. They are written for the agent; here is what each one means for you.

1. **Never approve a plan the user would not; when in doubt, ask.** The agent may approve only a
   low-risk plan (creates and in-place updates, nothing replaced, nothing holding data deleted, no IAM
   or network-exposure change, no unexplained warning), and only if you have not asked to be consulted.
   Everything else it brings to you. [Approval](/docs/concepts/approval/).

2. **Destroy only on the user's explicit words.** A destroy plan is never approved by the agent. It
   presents the plan and asks "Ready to destroy these resources? This cannot be undone." A removal
   of one resource is an edit to the files; a destroy tears down everything in the workspace. The agent
   asks which you mean when it is unclear.

3. **Never answer a turf action's question for the user, and never weaken a trigger to get past it.**
   When a step of the apply asks for your decision, the agent asks you, quotes your words, and reports a
   "no" as a failure. It does not remove the trigger, loosen its condition or change `on_failure` to
   make the apply go through. [Turf actions](/docs/concepts/turf-actions/).

4. **Never force-unlock without the user's explicit approval.** A locked workspace usually means
   another run holds it, possibly one of yours still in flight. The agent tells you and asks before it
   breaks a lock. [Workspaces and backends](/docs/using/workspaces/).

5. **Never batch dependent tool calls: one call, its result, then the next.** `up`, then `plan`, then
   `apply`, each after reading the result before it. Two calls on one run at once would race, and the
   second would be refused as "being followed by another call".

6. **Never put a secret in the configuration.** Not in a `.tf` file, a `.tfvars` file or an overlay.
   Secrets reach providers through the engine's environment and reach the backend through the server's;
   a variable value goes to `open` or a start verb, never into a committed file.
   [Where credentials are read](/docs/environment/where-credentials-are-read/).

7. **The files are the user's: change them only when asked, and say what you changed.** The agent edits
   a `.tf` or `*.turf.hcl` file only on your request, and loads the authoring skill before the first
   edit. Setting a variable's value is deployment, not an edit. It never rewrites a configuration to
   stage an apply or hard-codes a value to skip a round.

## Two more the agent lives by

**Nothing runs off-plan.** `apply` is the approval of one plan, named by its digest. If the files change
after the plan, the run ends `stale` and nothing is applied. There is no `-target`, and nothing is
retried: a failed change settles, the round finishes what is independent of it, and the agent fixes the
cause and runs `up` again.

**A plan goes to policy first.** Before a non-trivial plan, the agent hands the plan document to your
policy tools, if you have them. A deny means do not apply.

The full text the server hands the agent is in [Server instructions](/docs/reference/instructions/).
