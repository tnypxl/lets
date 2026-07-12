---
domain: '{name}'
# requires_domain: {name}
# Uncomment and set when this workflow's verb guidance requires a companion domain.
# The skill enforces the pairing at resolution time — deterministically, before
# the verb runs. See scripts/resolve-context.sh for the resolution and
# coupling logic.
---

# Workflow: {Name}

How the four verbs behave when a stem sets `workflow: {name}`. Read as a preset when that stem runs any verb; override per-project by placing a `{name}.md` under the project's `.agents/workflows/`.

The presence of a section below is the signal that this workflow shapes that verb. An absent section leaves the verb at its default — delete any sections you do not want to tune rather than leave them empty. Body structure beyond the section headers is recommended taste, enforced by nothing.

## discuss

[How this workflow shapes the discuss phase — what the assistant surfaces first, how the objective and approach are framed, any structural or tonal conventions this workflow brings to notebook.md.]

## research

[How this workflow shapes investigation — what kinds of sources to prioritize, how findings are organized, any conventions for the inward (project prior art) vs. outward (field conventions) pass.]

## plan

[How this workflow shapes decomposition — granularity of tasks, ordering conventions, what belongs in a task title vs. its body, any coupling rules or phase gates this workflow imposes.]

## execute

[How this workflow shapes delivery — code style, prose register, artifact hygiene, anything specific to what this workflow produces that the executor should hold to.]

> This is a starter shape. The sections above are recommended taste, enforced by nothing — add, remove, or restructure them freely for your workflow. Tend it to your actual defaults.
