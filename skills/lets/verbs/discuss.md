---
title: Discuss
status: active
---

Discuss writes `notebook.md` as a direct conversation between human and assistant — no subagent drives it. Predict narrow first: surface the single highest-leverage thread implied by what the human just said, since a wrong narrow prediction is cheap to correct and a wide one entangles everything. Open one or two questions per turn — enough to move forward, few enough that the answers stay consistent with each other. When a single fact would settle a thread, hand off to the `researcher` for a narrow inline check (`--role worker --mode inline`): it returns the fact and writes nothing. Each turn, advance at most one or two of OBJECTIVE, APPROACH, or a `Q#` — never all three from a single exchange.
