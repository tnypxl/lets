---
title: Setup
status: active
---

`/lets setup {kind} {name}` authors one reference — a domain or a workflow — through a single guided flow: interview, then draft, then install. Working state lives in `~/.lets/setup/{kind}.{name}/` (`interview.md`, `draft.md`), never in a stem; a rerun for the same name reloads that folder and asks only what changed. The emitted `<template>` defines the target shape, and any `<existing>` segment is the file being revised — read it before asking anything, and never start blind. Voice inverts here: a reference exists to define stems, verbs, domains, and workflows, so that vocabulary belongs in the file and must not be scrubbed; every other artifact keeps the standard scrub.

## interview

Derive the script from the emitted `<template>`, one or two questions per section in template order: scope boundary first, then the domain's deliverable forms or the workflow's verbs to tune, then rules hard enough to be directives, artifact sections worth reshaping (`## template:*`), coupling, and the install target. Ask one question per turn and append each answer to `interview.md` as it lands — free-form detours are welcome, the script is the completeness checklist, and drafting starts only when every scripted question is answered or explicitly skipped.

## draft

Write `draft.md` in the template's shape and within its authoring budget: prose for judgment, `## directives` only for rules whose violation is a defect, `## template:*` only for sections the verb artifacts genuinely need reshaped. Show the draft and revise at the human's pace, one increment per turn.

## install

Confirm the destination before writing — `$PWD/.agents/{kind}s/{name}.md` (project override) or `$HOME/.agents/{kind}s/{name}.md` (default floor) — and say so when the project path would shadow an existing global file of the same name. Copy the confirmed draft to that path and leave the workspace in place as rerun memory.
