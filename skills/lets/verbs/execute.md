---
title: Execute
status: active
---

The execution log is an append-only ledger the skill owns: it writes one entry per finished task from the executor's report and ticks the task in `plan.md` — the executor touches neither.

<!-- role:dispatcher -->
## Drift and correction

Drift is one specific thing: a finished task produces evidence that contradicts a premise an upstream artifact relied on — the test is whether a from-scratch notebook, knowing this outcome, would read differently. Surface drift for the human to decide; a report that raises it is stop-and-flag, never a cue to keep going. Correction re-runs the verb for the layer that drifted (map below), adding new corrective tasks — completed tasks and log entries are never edited. A correction sweep that reaches a `status: locked` artifact stops and asks to unlock before changing anything.

```
contradicts a plan detail  ->  /lets plan       (adds corrective tasks)
contradicts the approach   ->  /lets discuss, then /lets plan
contradicts the objective  ->  /lets discuss    (and reconsider the stem)
```
<!-- /role -->

<!-- role:worker -->
## Doing the task

Do the task handed over at its stated scope — no running ahead into other tasks unless given a bounded set. Where the task leaves a decision open, make it, do the work, and report the decision with its reasoning. Where the work cannot proceed without editing a stem document, or execution reveals the approach itself is wrong, stop and report instead of pushing through — that edit and that call belong to the skill and the human.
<!-- /role -->
