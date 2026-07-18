---
name: lets
description: |
  - Stage a piece of work through one collaborative harness.
  - Invoked as `/lets {verb} {prompt}` where verb is one of discuss, research, plan, execute, setup.
  - Use whenever the human says "let's discuss/research/plan/execute".
  - Use whenever the human wants to author a domain or workflow reference (`/lets setup {domain|workflow} {name}`).
  - Use whenever the human references a stem's notebook.md/research.md/plan.md/execute.md.
  - Use whenever the human wants to think a piece of work through in stages and capture it in durable documents — for code, writing, decisions, research, or personal planning.
---

# /lets

This skill is a thin dispatcher: it resolves the verb, the stem, and the target artifact, then runs the router below, whose emitted `<lets_context>` is the playbook for the turn — read the content files only through it, never directly.

| Verb | Artifact | Subagent |
|---|---|---|
| discuss | `notebook.md` | — (direct conversation) |
| research | `research.md` | `researcher` |
| plan | `plan.md` | `planner` |
| execute | `execute.md` | `executor` |
| setup | `.agents/{kind}s/{name}.md` | — (guided flow) |

## Dispatch

Resolve the verb — the input's first token, one of the table's five — and if it is missing or unrecognized, ask which is meant and stop; for `setup`, parse `{kind} {name}` from the rest of the input (kind `domain` or `workflow`; ask and stop when either is missing), run the router with `--activity setup --kind {kind} --name {name}`, and follow the emitted flow — no stem, no session.yml, no artifact scaffolding. For the four stem verbs, read `session.yml` at the project root for `stem` and `note`; when it or the stem folder `{index}.{stem}` beside it is absent, ask for a stem name and create them (next index = highest existing + 1, else 1); scaffold a missing artifact with `status: active` from `{skill-dir}/scripts/resolve-context.sh --activity {verb} --template`, which merges any domain/workflow template overrides into the base, and if the target's frontmatter is `status: locked`, state that it is read-only and stop. Run the router with the working directory at the project root, invoking it by its path under this skill's directory — never `cd` into the skill directory, since the router resolves the project from the cwd; on nonzero exit surface its stderr verbatim and stop, and on success follow the emitted playbook as written — it carries this verb's cadence, behavior, and any resolved domain/workflow content and directives.

```
{skill-dir}/scripts/resolve-context.sh --activity {verb} --role dispatcher
{skill-dir}/scripts/resolve-context.sh --activity setup --kind {domain|workflow} --name {name}
```

## Task Contract

Every hand-off to `researcher`, `planner`, or `executor` is the assembled contract below, handed over whole — it carries only the bounded scope and exact upstream slices, because the worker self-loads its own behavior, voice, and domain/workflow content via `--role worker`.

```xml
<task_contract>
  {verb}research | plan | execute{/verb}
  {stem}{stem name}{/stem}
  {scope}
    {bounded description of what this subagent is being asked to do —
     never hand a subagent the full notebook/research/plan; hand it
     the slice relevant to this call}
  {/scope}
  <upstream>
    <!-- omit any that don't apply; embed content, never a bare path to
         re-read. For T#/Q# ids, get the exact slice via:
         {skill-dir}/scripts/read-section.sh {file} {T#|Q#} -->
    <approach_ref>{notebook.md APPROACH section, pasted verbatim}</approach_ref>
    <research_ref>{relevant excerpt of research.md, pasted verbatim}</research_ref>
    <plan_ref>{output of {skill-dir}/scripts/read-section.sh plan.md T#, for the task(s) in scope}</plan_ref>
  </upstream>
</task_contract>
```
