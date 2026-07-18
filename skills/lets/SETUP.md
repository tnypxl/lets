---
title: Setup
status: active
---

Setup mode is the overlay the router layers on when `session.yml` sets `setup: domain` or `setup: workflow` — read it alongside `CORE.md` and the verb slice, not instead of them. The deliverable redirects: the stem's target stops being the four stem documents and becomes `.agents/domains/{name}.md` or `.agents/workflows/{name}.md`. Confirm which of the two eligible paths is intended — `$PWD/.agents/` (project override) or `$HOME/.agents/` (default floor) — before writing, and say so when the project path would shadow an existing global file of the same name. The consumption selectors (`domain:`/`workflow:` on a notebook) are ignored while authoring — a setup stem builds a reference, it does not consume one. Voice inverts: a setup deliverable exists to define stems, verbs, domains, and workflows, so that vocabulary belongs in the file and must not be scrubbed. The inversion holds only for setup deliverables; every other artifact keeps the standard scrub.

## discuss

Shape what the reference is *for* before what it says: settle the destination path and the boundary of what the file governs. Where a same-name file exists at either path, read it first — discuss decides what changes or what's new, never starting blind. The templates (`templates/domain.md`, `templates/workflow.md`) define the target shape; settling structure here is choosing which of their sections the reference will use.

## research

Two wells, in order: inward first — existing `.agents/domains/` and `.agents/workflows/` files, their naming patterns and section conventions — then outward, field conventions via web search or local documents outside `.agents/`. On a greenfield project with no prior `.agents/` content, outward is the only well. Findings / Implications / Gaps still applies; inward and outward findings are just findings, kept in gathering order.

## plan

Decompose the reference into its writable sections, not implementation tasks, ordered by what later sections build on. A domain decomposes as one task for the scope/intro plus one per standards-area section; a workflow as one task for the frontmatter (default domain, coupling declarations) plus one per per-verb section actually present. An absent workflow section leaves that verb at its default — do not plan a section the file doesn't need.

## execute

Write the file at the human's pace, on the same cadence as every verb: advance one increment, keep it clean, hand back. Carry the vocabulary inversion into every section written — name stems, verbs, domains, and workflows as what they are, not as euphemisms. The setup stem's own `execute.md` remains a normal ledger: the deliverable is the reference file itself, and the log records the passes that built it.
