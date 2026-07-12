---
title: Execute
status: active
---

Execute writes `execute.md`. The skill dispatches each task to the `executor`
subagent, then folds the report back into the log and ticks the plan itself.

## Drift and correction

<!-- role:dispatcher -->
**Drift** is one specific thing: a finished task produces evidence that
contradicts an assumption an upstream artifact was built on — a premise
turning out *wrong*. A hard task is just a hard task. A fresh idea is a new
open question or a new stem. Drift is the case where the outcome overturns a
premise already relied on.

The test, asked after a task: *if I rewrote the notebook from scratch right
now, knowing what this task's outcome taught us, would it say something
different?* Yes → drift.

The human pulls the trigger; the skill executes the sweep. **Correction is
re-running the verb for the layer that drifted.** Drift has a depth, and the
depth is the reach:

```
contradicts a plan detail   →  /lets plan      (creates 1 or more corrective tasks)
contradicts the approach    →  /lets discuss   then  /lets plan
contradicts the objective   →  /lets discuss   (and reconsider the stem)
```

Completed tasks stay as they are — they remain useful context — so correction
adds new corrective tasks. First-time work and correction use the same verbs,
whether building or repairing.

The skill surfaces drift for the human to decide; it never resolves it
unilaterally. A task report that raises drift is a stop-and-flag, not a cue
to keep going.
<!-- /role -->

## The log

The execution log is a ledger: append-only, chronological, one entry per
finished task, in task order. An entry is never rewritten once written —
correction adds a new entry for the corrective task, it does not edit the
old one. The skill owns the log: it writes the entry from the executor's
report and ticks the task in `plan.md`; the executor never touches either.

## The executor

<!-- role:worker -->
The executor is the implementation heavy-lifter: it does a task's real work
and returns a report the skill turns into a log entry. It is the only
workflow subagent that writes files, and its write-ownership is scoped
tightly — external artifacts only, the code, prose, and configs the task
produces. It never writes `session.yml`, never sets `status:`, and never
touches a stem document (`notebook.md`, `research.md`, `plan.md`,
`execute.md`); the plan and the log are the skill's to write, not the
executor's.

Do the task handed over, at its stated scope — no running ahead into other
tasks unless asked for a bounded set. Where the task leaves a decision open,
make it, do the work, and report the decision with its reasoning; surface
anything that affects scope or approach prominently. Where the work cannot
proceed without editing a stem document, stop and report that instead of
doing it — that edit belongs to the skill.
<!-- /role -->
