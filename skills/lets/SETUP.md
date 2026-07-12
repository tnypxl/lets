---
title: Setup
status: active
---

The overlay the router layers onto the normal slice when `session.yml` sets
`setup: domain` or `setup: workflow`. It carries only what setup mode changes
relative to the four verbs' default behavior — read alongside `CORE.md` and
the matching `verbs/*.md` file, not instead of them.

## The two globals

**Deliverable redirect.** The stem's artifact target stops being the four
stem documents (`notebook.md`, `research.md`, `plan.md`, `execute.md`) and
becomes a single reference file: `.agents/domains/{name}.md` or
`.agents/workflows/{name}.md`. Two paths are eligible — `$PWD/.agents/...`
(project override) or `$HOME/.agents/...` (default floor). Confirm which one
is intended before writing; if the project path is chosen and a file of the
same name already exists at the global path, say so — the project copy will
override it. The consumption selectors (`domain:` / `workflow:` on a
notebook) are ignored while authoring — a setup stem builds a reference, it
does not consume one.

**Voice inversion.** Every other deliverable this harness produces scrubs
harness vocabulary — stem, verb, task, open question — so the output reads as
its own domain, not as a trace of the process that made it. A setup
deliverable inverts that rule: it exists to define stems, verbs, domains, and
workflows, so that vocabulary belongs in the file and must not be scrubbed
out. This inversion holds only for setup deliverables; every other artifact
keeps the standard scrub.

## discuss

Shape what the reference is *for* before shaping what it says. Settle two
things through conversation: which of the two eligible paths it's headed to,
and the boundary of what the file should govern (a domain's code style and
citation conventions, or a workflow's per-verb behavioral tuning). Where a
domain or workflow already exists at either path under the same name, read it
first — discuss is deciding what changes or what's new, not starting blind.
The templates (`templates/domain.md`, `templates/workflow.md`) define the
target shape; settling on structure here is settling which of their sections
the reference will actually use.

## research

Two wells, in order. **Inward first** — existing `.agents/domains/` and
`.agents/workflows/` files: naming patterns, section conventions, the house
style this project has already settled on. **Outward second** — field
conventions via web search, or local documents outside the project's
`.agents/` tree. On a greenfield project with no prior `.agents/` content,
outward is the only well available. The inward-then-outward order is what
sets setup research apart from the standard verb: a new reference should
match its siblings before it reaches for the wider field. Findings /
Implications / Gaps still applies; inward and outward findings are just
findings, kept in the order they were gathered.

## plan

Decompose the reference into its writable sections, not into implementation
tasks. Domain and workflow files follow fixed shapes: a domain's sections
answer "what does this codebase or field expect" (structure, conventions,
citation format, whatever the domain calls for); a workflow's sections are
one-per-verb, present only where that workflow actually tunes the verb's
default behavior — an absent section leaves that verb alone, so do not plan a
section the file doesn't need. Order sections by what later sections build
on, same as any other decomposition.

## execute

Write the file. No imposed granularity — the human drives how much lands per
pass, same cadence discipline as the other three verbs (advance one
increment, keep it clean, hand back). Carry the vocabulary inversion from the
preamble into every section written here: name things as stems, verbs,
domains, and workflows where that is what they are, not as euphemisms
reaching for scrub-compliance. The deliverable is the reference file itself;
there is no separate log entry to reconcile against, because the execution
log this overlay writes into is the setup stem's own `execute.md` — that
stays a normal ledger even though the thing it is a ledger *of* is a
reference file instead of code or prose.
