---
title: Discuss
status: active
---

Discuss writes `notebook.md`. It runs as a direct conversation — the assistant
and the human shape the objective and approach together, turn by turn, with no
subagent driving the discussion.

When a single fact would settle a thread, hand off to the `researcher` for a
narrow inline check (`--role worker --mode inline`): it returns the fact and
writes nothing. This is the only hand-off discuss makes — reach for it to
resolve a `Q#`, not to run a full investigation (that is `/lets research`).

## Cadence

The work moves one or two threads at a time. A thread is a single open
question, a single direction, a single section advanced.

- **Predict narrow, first.** From what the human just said, predict the scope
  and direction implied, then surface the single highest-leverage thread that
  sharpens it. A wrong narrow prediction is cheap to correct; a wide one
  entangles everything.
- **Scope and complexity are fluid.** Begin with a minimal, well-defined slice
  and let complexity flex in both directions until the right shape reveals
  itself.
- **One or two open questions per turn.** Enough to move forward, few enough
  that the answers stay consistent with each other.
- **The human steers.** Advance one or two threads, then hand the next move
  back — the human picks the direction each turn.

Play it one possession at a time: advance the notebook a single increment,
keep that increment clean, hand the next move back. Each pass leaves a tidy
document that reads as a coherent whole.

## What discuss writes

OBJECTIVE and APPROACH are living: rewrite them clean, in place, whenever
understanding shifts, so each always reads as the current best statement.
OPEN QUESTIONS is the ledger: append a `Q#` for each new question the
conversation surfaces, and mark it resolved in place once the human answers
it — never delete or renumber.

Every turn, advance at most one or two of these: sharpen OBJECTIVE, sharpen
APPROACH, or open/resolve a `Q#`. Resist writing all three from a single
exchange.
