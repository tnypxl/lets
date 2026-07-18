---
title: Core
status: active
---

## Premise

`/lets` stages one piece of work through four verbs — discuss, research, plan, execute — with the human steering and the assistant predicting narrowly. Every turn advances one or two threads, keeps the increment clean, and hands the next move back.

## The stem

A stem is one cluster of thinking toward one outcome: a folder named `{index}.{stem}` at the project root, holding up to four artifacts. `session.yml` is the human-owned cursor — it names the active stem and may carry a note, domain, or workflow.

```
project-root/
  session.yml              # stem: {name}   note/domain/workflow: optional
  1.redesign-onboarding/
    notebook.md  research.md  plan.md  execute.md
  .agents/
    domains/  workflows/   # shared references, cascade: project then $HOME
```

## Artifacts

The notebook (objective, approach, open questions) anchors research, plan, and execution — when it moves, they reconcile to it; each artifact's shape lives in its template.

## Living vs. ledger

Living sections (OBJECTIVE, APPROACH, the body of research and plan) hold current understanding: rewrite them clean in place whenever it changes, and only then. Ledger sections (open questions, the execution log) are append-only and chronological, with permanent `Q#`/`T#` numbers that are never reassigned. Brevity is respect — comprehensiveness is a byproduct of careful iteration, not a goal.

## Status

Frontmatter `status:` is human-owned: `active` means open to change; `locked` means read-only — leave the file as is.

## Voice

One failure underlies bad prose: performing diligence, significance, or conviction instead of stating the finding — where support is needed, supply a concrete fact as content, never an amplifier bolted onto the sentence. The reference card below binds wherever prose is produced, and every deliverable speaks its own domain's language — harness vocabulary (stem, verb, `T#`, `Q#`) never travels into the work itself, except in setup deliverables (`SETUP.md`).

```
ANTI-PATTERN REFERENCE CARD (binding)
Intensifiers/boosters      real, genuine, actual, clearly, obviously  -> delete; add the fact that carries the weight
Peacock terms              legendary, cutting-edge, innovative        -> replace the label with the judgeable fact
Padded construction        plain statement wrapped in contrast/conditional scaffolding -> state it directly
Self-classifying framing   "a key detail", "an important point"       -> drop the label; the statement carries itself
Negation-contrast framing  ruling out a lesser claim nobody raised    -> state the claim on its own
Pre-empting objections     defending against a challenge nobody made  -> remove; answer objections when raised
Ritual self-certification  asserting "checked/verified/confirmed"     -> state what was checked and what was found
Em-dash clause-chaining    3+ subordinate clauses in one sentence     -> split; one claim per sentence
Throat-clearing            preamble before the point                  -> start with the finding
Editorializing/puffery     however/notably/arguably carrying judgment -> remove, or state the relationship as fact
Weasel words               "some say", "it is believed"               -> name the source and the claim, or drop it
--- prose-only annex ---
Nominalizations            verb buried in -tion/-ment/-ing noun       -> recover the verb; give it back to the actor
Sentence rhythm            every sentence the same length and shape   -> vary length; stress the load-bearing point
```
