---
# requires_workflow: {name}
# Uncomment and set when this domain's deliverables require a companion workflow.
# The skill enforces the pairing at resolution time — deterministically, before
# the verb runs. See scripts/resolve-context.sh for the resolution and
# coupling logic.
---

# Domain: {Name}

<!-- What {name} work cares about and the standards its deliverables follow.
     Read as context when a stem sets `domain: {name}`; override per-project
     by placing a `{name}.md` under the project's `.agents/domains/`.

     Authoring budget: keep a domain at or under 14 countable sentences
     (a sentence, list item, or table row each count as one) — the harness
     reads the emitted portion inside a 40-sentence turn. `## directives`
     and `## template:*` sections never emit into a turn; bulk detail
     belongs in a fenced reference card, exempt from the count when
     introduced by one counted sentence declaring it binding.

     Open with one or two sentences of scope — what work this domain
     governs — before the first section. -->

## deliverables

<!-- The forms a deliverable in this domain takes, one per line:
     `- {form}: {one-line definition}`. When this section exists, discuss
     holds the APPROACH to naming one (`Deliverable: {form} — {name}`) and
     the router blocks plan until it does. -->

## {Primary standards area}

<!-- One clear rule per bullet — what deliverables in this area must do or avoid. -->

## directives

<!-- Typed per-verb rules, one per line:
     `- {verb|all}: {MUST|NEVER|GATE} {rule}`
     The router emits only the lines matching the running verb, last in the
     turn, and they bind — reserve them for rules whose violation is a
     defect, and keep judgment guidance in the prose sections above. -->

## template:{artifact}

<!-- Optional overrides for a verb artifact's template; {artifact} is one of
     notebook|research|plan|execute, one section per artifact. Each
     `### {SECTION}` block here replaces the section of that name in the
     base template, or is appended as a new one when nothing matches
     (task/entry shapes are targets too: `### T-SHAPE`, `### ENTRY-SHAPE`).
     Consumed only at scaffold time via `resolve-context.sh --template`.

     This is a starter shape: only `## deliverables`, `## directives`, and
     `## template:*` carry mechanics — delete any you do not need, and
     restructure the standards sections freely. Deliverable hygiene (no
     harness vocabulary in the work) is CORE's rule; do not restate it. -->
