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

This skill is a thin dispatcher. It resolves the verb, the stem, and the
target artifact, then hands the turn to `./scripts/resolve-context.sh` — the
router that assembles the actual playbook (concepts, cadence, drift,
selectors, authoring mechanics) from `./reference/CORE.md`, `./verbs/*.md`,
and `./SETUP.md`. Read those files only through the router's output, not
directly — that's the context budget this skill is designed around.

## Quick Reference

| Verb | Artifact | Subagent | Template |
|---|---|---|---|
| discuss | `notebook.md` | — (direct conversation) | `./templates/notebook.md` |
| research | `research.md` | `researcher` | `./templates/research.md` |
| plan | `plan.md` | `planner` | `./templates/plan.md` |
| execute | `execute.md` | `executor` | `./templates/execute.md` |

Setup mode redirects the artifact (not the verb) to `.agents/domains/{stem}.md`
or `.agents/workflows/{stem}.md`, using `./templates/domain.md` or
`./templates/workflow.md` — see step 3.

## Guardrails

- Never write to an artifact whose frontmatter is `status: locked`. Say so and stop (step 4).
- Never delegate to a subagent without assembling the `<task_contract>` below and handing it over whole.
- Never dump more than one or two threads/questions/tasks into an artifact in a single turn — the router's emitted playbook (step 5) carries this verb's cadence; meter to it, then hand the turn back.
- Never resolve drift yourself. Surface the suspicion; the human decides whether to run the correction sweep (`verbs/execute.md` § Drift and correction).
- In setup mode, never scrub harness vocabulary (domain, workflow, stem, verb) from the output — that inversion is correct there and only there (`SETUP.md`).

## Dispatch

Input: `{verb} {prompt}`. First token is the verb; remainder is the prompt.

1. **Resolve verb.** Must be one of `discuss`, `research`, `plan`, `execute`. If missing or unrecognized: ask which verb is meant, then stop until answered.
2. **Resolve stem.** Read `session.yml` at the project root for `stem`, `note:`, and `setup:` (optional; `domain` or `workflow`).
   - If `session.yml` is missing: ask the human for a stem name, create `session.yml` with that `stem` and empty `note`, then continue.
   - Find the stem folder beside `session.yml` (`{index}.{stem}`). If absent: allocate the next index (highest existing stem index + 1, else 1) and create the folder.
3. **Resolve artifact.**
   - Normally: map verb → file per the Quick Reference table. If the file doesn't exist, scaffold it from the matching template with `status: active`.
   - If `setup:` is set in `session.yml`: the target is the reference file being authored instead — `setup: domain` → `.agents/domains/{stem}.md`, `setup: workflow` → `.agents/workflows/{stem}.md` — scaffolded from `./templates/domain.md` or `./templates/workflow.md` with `status: active` if absent. Confirm with the human which path (project `.agents/` or `$HOME/.agents/`) is intended before writing there for the first time.
4. **Lock guard.** If the target artifact's frontmatter is `status: locked`: state that it's read-only and stop — do not proceed to the playbook. (Exception: during an execute-driven correction sweep, if the sweep reaches a locked upstream artifact, surface the contradiction and ask to unlock before changing anything.)
5. **Run the router.** From the skill's own directory, with the project root as the working directory, run:
   ```
   ./scripts/resolve-context.sh --activity {verb} --role dispatcher
   ```
   If `setup:` is set in `session.yml`, append `--setup {domain|workflow}` and say plainly that this stem is in authoring mode before continuing.
   - Nonzero exit: the script has already printed the resolution or coupling failure to stderr — surface that message verbatim and stop.
   - Zero exit: the emitted markdown *is* the playbook for this turn. Follow it as written — it already carries the stem/artifact/status contract, this verb's cadence and behavior, the setup overlay (when applicable), and any resolved domain/workflow content. There is nothing here to parse into variables.
6. **Load the voice.** Read `./reference/VOICE.md`. It governs everything produced this turn — conversation and artifact alike. (The router's output points to this file but does not inline it, since it governs the conversation turn as much as the artifact — read it directly, every turn.)
7. **Run the verb's playbook** (the router's step-5 output), advancing one or two threads at a time, then hand the next move back to the human.

## Task Contract

Every subagent hand-off (`researcher`, `planner`, `executor`) is a single assembled payload, not a paragraph of instructions restated ad hoc. The subagent self-loads its own verb behavior by running `./scripts/resolve-context.sh --activity {verb} --role worker` — so this contract only carries what the subagent cannot derive that way: the bounded scope, and the exact upstream slices it needs. Build it from this template each time:

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
  <governing_refs>
    <voice>{absolute path to reference/VOICE.md}</voice>
  </governing_refs>
</task_contract>
```

Domain and workflow standards are not carried here — `--role worker` already
folds the resolved domain/workflow content into the subagent's own router
call, so restating it in this contract would double-supply it.
