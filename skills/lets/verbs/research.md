---
title: Research
status: active
---

Research grounds the notebook's approach in real material before plan commits
to tasks built on it. It runs in one of two modes — a narrow inline fact-check
mid-conversation, or a full bounded investigation that writes `research.md`.
Which mode applies for a given call is the router's `--mode {full|inline}`
selection, not a decision made here.

<!-- role:dispatcher -->
## Metering

Hand the researcher a bounded scope, not the full notebook. In inline mode,
fold the returned fact into the conversation only if it matters — nothing
inline is written to `research.md`. In full mode, the researcher returns
grounded blocks; meter them into the document one or two threads at a time
rather than dumping the whole return in one pass. If a finding conflicts with
the notebook's Approach, surface that first and send the human back to
`discuss` rather than resolving it here.
<!-- /role -->

<!-- role:worker -->
## Inline lookup (during discuss)

A narrow, specific fact is needed mid-conversation — a price, a version, an
API shape, a definition. Get it and return it tightly.

- Answer exactly what was asked, with the source. No survey, no implications,
  no document framing.
- This is ephemeral grounding. Nothing returned here is written to
  `research.md`.

## Investigation (for /lets research)

The scope handed over is already bounded. Fan out across real material and
return grounded blocks.

- **Investigate only within the scope given.** Do not re-scope, broaden, or
  drift. A tight investigation produces clean implications; an expanded one
  produces mush. If the scope looks wrong or too narrow, say so and stop —
  do not silently widen it.
- Fan out efficiently: read code, grep patterns, fetch and search the web.
  Prefer primary sources over inference.

Keep observation separate from interpretation:

- **Findings** — factual, neutral, sourced (`file:line`, URL,
  `pdf|document:page-number`). No interpretation.
- **Implications** — a distinct step: what the findings mean for the
  notebook's approach and plan. Never folded into Findings.
- **Gaps** — what could not be determined, stated plainly. Never buried — a
  buried gap becomes a contradiction after the plan has committed.
- If a finding **conflicts with the notebook's Approach**, call it out first
  and prominently.

## Boundaries

No write tools by design. Never write `session.yml` or any stem document.
The deliverable is the final message; the skill meters it in.

## Return format (investigation mode)

Shape each field by what it holds: a single fact stays inline, anything with
more than one part becomes a bullet list — never inline `(1)…(2)…(3)`
enumeration.

```
## FINDINGS
- <neutral observation, with source>

## IMPLICATIONS
- <what the findings mean for the approach/plan — kept distinct from Findings>

## GAPS
- <what could not be determined>

## CONFLICTS   (only if a finding contradicts the Approach — put this first)
- <what was found, why it conflicts, what it implies>
```
<!-- /role -->
