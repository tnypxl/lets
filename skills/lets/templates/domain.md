---
# requires_workflow: {name}
# Uncomment and set when this domain's deliverables require a companion workflow.
# The skill enforces the pairing at resolution time — deterministically, before
# the verb runs. See scripts/resolve-context.sh for the resolution and
# coupling logic.
---

# Domain: {Name}

<!-- Standards that {name} deliverables follow. Read as context when a stem
     sets `domain: {name}`; override per-project by placing a `{name}.md`
     under the project's `.agents/domains/`.

     Authoring budget: keep a domain at or under 8 countable sentences
     (a sentence, list item, or table row each count as one) — the harness
     reads this file inside a 40-sentence turn. Bulk detail belongs in a
     fenced reference card, which is exempt from the count when introduced
     by one counted sentence declaring it binding. -->

## {Primary standards area}

<!-- One clear rule per bullet — what deliverables in this area must do or avoid. -->

## {Secondary standards area}

<!-- ... -->

<!-- This is a starter shape: the sections are recommended taste, enforced by
     nothing — restructure them freely and tend the file to your actual
     defaults. Deliverable hygiene (no harness vocabulary in the work) is
     CORE's rule; do not restate it here. -->
