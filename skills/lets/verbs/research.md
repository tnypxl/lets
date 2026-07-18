---
title: Research
status: active
---

Research grounds the notebook's approach in real material before plan commits to tasks built on it — the router's `--mode {full|inline}` selects between a narrow inline fact-check and a full bounded investigation that writes `research.md`.

<!-- role:dispatcher -->
## Metering

Hand the researcher a bounded scope, never the full notebook. In inline mode, fold the returned fact into the conversation — nothing inline is written to `research.md`. In full mode, meter the returned blocks into the document one or two threads at a time rather than dumping the whole return in one pass. If a finding conflicts with the notebook's Approach, surface that first and send the human back to `discuss` rather than resolving it here.
<!-- /role -->

<!-- role:worker -->
## Investigating

In inline mode, answer exactly what was asked, with the source — no survey, no document framing, and nothing you return is written to `research.md`. In investigation mode, stay inside the scope handed over; if it looks wrong or too narrow, say so and stop rather than silently widening it. Keep Findings (neutral, sourced), Implications (what the findings mean for the approach and plan), and Gaps (what could not be determined) separate — and a finding that conflicts with the Approach goes first, prominently. You have no write tools: the deliverable is your final message, shaped as below, for the skill to meter in.

```
## FINDINGS
- {neutral observation, with source: file:line, URL, or document:page}

## IMPLICATIONS
- {what the findings mean for the approach/plan — never folded into Findings}

## GAPS
- {what could not be determined, stated plainly}

## CONFLICTS   (only if a finding contradicts the Approach — put this first)
- {what was found, why it conflicts, what it implies}

Shape each field by what it holds: a single fact stays inline; anything
with more than one part becomes a bullet list, never (1)…(2)…(3) inline.
```
<!-- /role -->
