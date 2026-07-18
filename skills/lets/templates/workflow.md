---
domain: '{name}'
# requires_domain: {name}
# Uncomment and set when this workflow's verb guidance requires a companion domain.
# The skill enforces the pairing at resolution time — deterministically, before
# the verb runs. See scripts/resolve-context.sh for the resolution and
# coupling logic.
---

# Workflow: {Name}

<!-- How the four verbs behave when a stem sets `workflow: {name}`. Read as a
     preset when that stem runs any verb; override per-project by placing a
     `{name}.md` under the project's `.agents/workflows/`.

     The presence of a section below is the signal that this workflow shapes
     that verb — an absent section leaves the verb at its default, so delete
     any section you do not want to tune rather than leave it empty.

     Authoring budget: keep a workflow at or under 4 countable sentences
     (a sentence, list item, or table row each count as one) — the harness
     reads this file inside a 40-sentence turn. -->

## discuss

<!-- What the assistant surfaces first; how objective and approach are framed. -->

## research

<!-- Sources to prioritize; how findings are organized; inward vs. outward pass. -->

## plan

<!-- Task granularity, ordering conventions, coupling rules or phase gates. -->

## execute

<!-- Code style, prose register, completion gates the executor holds to. -->
