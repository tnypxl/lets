---
name: lets
description: |
  - Stage a piece of work through one collaborative harness.
  - Invoked as `/lets {verb} {prompt}` where verb is one of discuss, research, plan, execute.
  - Use whenever the human says "let's discuss/research/plan/execute".
  - Use whenever the human references a stem's notebook.md/research.md/plan.md/execute.md.
  - Use whenever the human wants to think a piece of work through in stages and capture it in durable documents — for code, writing, decisions, research, or personal planning.
---

# /lets

This skill is a thin dispatcher: it resolves the verb, the stem, and the target artifact, then runs the router below, whose emitted `<lets_context>` is the playbook for the turn — read the content files only through it, never directly.

| Verb | Artifact | Subagent | Template |
|---|---|---|---|
| discuss | `notebook.md` | — (direct conversation) | `./templates/notebook.md` |
| research | `research.md` | `researcher` | `./templates/research.md` |
| plan | `plan.md` | `planner` | `./templates/plan.md` |
| execute | `execute.md` | `executor` | `./templates/execute.md` |

## Dispatch

Resolve the verb — the input's first token, one of the table's four — and if it is missing or unrecognized, ask which is meant and stop. Read `session.yml` at the project root for `stem`, `note`, and optional `setup`; when it or the stem folder `{index}.{stem}` beside it is absent, ask for a stem name and create them (next index = highest existing + 1, else 1). Scaffold a missing artifact from its template with `status: active` — in setup mode (`setup: domain|workflow` in `session.yml`) the target is `.agents/domains/{stem}.md` or `.agents/workflows/{stem}.md` instead, confirming project vs `$HOME` path before the first write — and if the target's frontmatter is `status: locked`, state that it is read-only and stop. Run the router from the skill's own directory with the project root as the working directory; on nonzero exit surface its stderr verbatim and stop, and on success follow the emitted playbook as written — it carries this verb's cadence, behavior, and any resolved domain/workflow or setup overlay.

```
./scripts/resolve-context.sh --activity {verb} --role dispatcher [--setup domain|workflow]
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
         ./scripts/read-section.sh {file} {T#|Q#} -->
    <approach_ref>{notebook.md APPROACH section, pasted verbatim}</approach_ref>
    <research_ref>{relevant excerpt of research.md, pasted verbatim}</research_ref>
    <plan_ref>{output of ./scripts/read-section.sh plan.md T#, for the task(s) in scope}</plan_ref>
  </upstream>
</task_contract>
```
