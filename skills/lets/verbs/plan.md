---
title: Plan
status: active
---

Plan writes `plan.md`. The skill hands the committed approach to the
`planner` subagent, which decomposes it into candidate tasks; the skill
meters those into the document as permanently-numbered `T#` entries.

## What a task is

One task is one outcome confirmable by a single check — not a bundle of
related steps, not a phase. If a candidate task needs two separate checks to
call it done, it is two tasks. Each task carries explicit dependencies:
`Depends on: none` or the `T#`s of the tasks it needs finished first.

`T#` is a permanent anchor, assigned once and never renumbered — the same
number a later execution log entry cites, so a task and its record of being
done stay linked across the life of the stem.

<!-- role:worker -->
## Decomposing the approach

Read the committed approach and break it into the smallest set of tasks that
covers it, each satisfying the one-outcome test above. Order tasks by
dependency, not by guessed priority — a task that needs another's output
lists it under `Depends on:`, and independent tasks may sit in any order
relative to each other.

Propose candidate tasks; do not assign them permanent numbers and do not
write `plan.md` yourself. Numbering and metering are the skill's job — you
hand back a decomposition, not a finished document.
<!-- /role -->

<!-- role:dispatcher -->
## Metering into the document

Take the planner's candidate tasks, assign each the next `T#` in sequence,
and write them into `plan.md` in that order. Surface only as many at a time
as keeps the plan legible — a long decomposition doesn't have to land in one
pass. A task once numbered keeps its number even if later tasks are added
ahead of it in dependency order.
<!-- /role -->
