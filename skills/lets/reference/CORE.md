---
title: Core
status: active
---

<!--toc:start-->

- [Core](#core)
  - [What the workflow is for](#what-the-workflow-is-for)
  - [The stem](#the-stem)
  - [The four artifacts](#the-four-artifacts)
  - [Living vs. ledger](#living-vs-ledger)
  - [Status](#status)
  - [Voice](#voice)

<!--toc:end-->

The universal layer behind `/lets`: what a stem is, what the four artifacts mean, the living-vs-ledger distinction, status/lock. Every verb file and every subagent gets this prepended to its slice — it is the one contract all four verbs share. Verb-specific behavior (cadence, drift, selectors, authoring) lives in its owning file, not here.

## What the workflow is for

A small harness for thinking a piece of work through in stages, collaboratively. The human steers; the assistant predicts narrowly and waits. It produces a handful of clean markdown documents that a person or assistant can pick up later and be correctly oriented. It is domain-agnostic: code, writing, infra decisions, research, planning — anything that benefits from being thought through.

## The stem

A **stem** is one cluster of thinking, planning, and execution toward one something. Each stem is a folder at the project root, named `{index}.{stem}` (index = the order the work began). A root listing is the chronology of the work.

```
project-root/
  session.yml              # active stem (+ optional note)
  1.redesign-onboarding/
    notebook.md  research.md  plan.md  execute.md
  2.auth-refactor/
  .agents/
    domains/  workflows/  documentation/  assets/    # shared references
```

`session.yml` is the cursor and holds one thing — which stem is active:

```yaml
stem: redesign-onboarding
note: optional free-form context
domain: coding # optional; project-wide fallback when the notebook omits it
workflow: writing # optional; project-wide fallback when the notebook omits it
```

It is human-owned. Switching work is editing one line. The `note:` field can carry usable context.

**Workspace footprint.** `/lets` writes `session.yml` and `{index}.{stem}/` folders **at the project root** — this is the intended workspace layout, not a scratch area. Pointed at an arbitrary repo, it will add these to the root; that is by design, so a stem's chronology sits beside the work it concerns.

## The four artifacts

| verb       | writes        | what it is                                  |
| ---------- | ------------- | ------------------------------------------- |
| `discuss`  | `notebook.md` | the durable anchor — objective and approach |
| `research` | `research.md` | deliberate investigation grounding the work |
| `plan`     | `plan.md`     | ordered tasks toward the approach           |
| `execute`  | `execute.md`  | the work done, and a running record of it   |

The notebook anchors the other three. Research, plan, and execution all hang off it; when it moves, they reconcile to it.

The notebook's shape:

```markdown
---
title:
status: active
domain: # optional; a name resolved against the domain cascade
workflow: # optional; a name resolved against the workflow cascade
---

## OBJECTIVE

What this work is for. One clear statement of the something.

## APPROACH

How the work is structured and why — the current best account, adaptive.

Rewritten clean as understanding shifts. Often short. May be empty until there is something real to say.

## OPEN QUESTIONS

- [ ] Q1: ...
- [x] Q2: ...
  - RESOLVED — ...

## NOTES (optional)
```

**NOTES** section is owned by the human — an optional section they add by hand to keep approach- or objective-adjacent context. The skill reads it for context and leaves the writing to them.

## Living vs. ledger

Every section is one of two types, and the type follows from the section itself — evident on sight:

- **Living** (OBJECTIVE, APPROACH, and the body of research/plan): holds the current understanding. Rewrite it clean _whenever it changes_, and only then, so it always reads as the best statement of where things stand _now_. When something shifts, fold it into the prose so the section stays one coherent account. Refrain from unnecessary verbosity or performative comprehensiveness. Brevity is respect. Comprehensiveness is a byproduct of careful iteration.
- **Ledger** (Open Questions, the execution log): append-only and chronological, with sequential, permanent numbering. Resolved questions are marked `[x]` and kept in place. The trail of how understanding got here lives here, freeing the living prose to state only where things stand now. A compound question is two questions — split it.

## Status

Frontmatter `status:` is `active` or `locked`. The human owns it; the skill reads it and follows.

- `active` — the default on creation; the artifact is open to change.
- `locked` — frozen. A locked artifact is read-only: the skill leaves the file as is, and a correction sweep (see the drift section in `verbs/execute.md`) that reaches one stops and asks to unlock.

## Voice

This section covers naming and vocabulary hygiene only. For the assertion-honesty contract — how a finding gets stated without performing diligence, significance, or conviction — see `reference/VOICE.md` (bundled alongside this contract, not part of the project's `.agents/` tree); that file is the authority on it, not restated here.

Internal vocabulary — task identifiers, phase names, control words — belongs to the workflow, and the work it produces speaks its own language. In code, configs, and generated text, name things for what they are in their own domain. A good name makes sense to someone who never read the plan.

**Exception — authoring mode.** A `setup` deliverable is _about_ the harness: it exists to define stems, verbs, domains, and workflows. The executor must carry that vocabulary, not scrub it — the inversion is the rule's own documented exception. Full authoring-mode mechanics live in `SETUP.md`.
