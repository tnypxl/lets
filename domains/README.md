# Domains

Domain references are optional, read-only context for a stem. A stem opts in by setting `domain: <name>` in its `notebook.md` frontmatter; `/lets` then resolves `<name>.md` against a cascade and reads the first hit when shaping deliverables (code style, citation format, document structure, naming conventions):

```
$PWD/.agents/domains/<name>.md          # project override — wins
~/.agents/domains/<name>.md             # the default floor (~/.agents/ is typically a symlink into the dotfiles tree)
```

A project overrides the default by placing its own `<name>.md`; the files here are the floor. A reference describes the *standards a domain's deliverables follow* — not the work itself, and not the harness. The skill reads these; it never writes them.

Prose deliverables carry a standing voice baseline from `../skills/lets/reference/CORE.md` § Voice, which applies whether or not a stem selects a domain. A selected domain adds standards on top of that baseline; it does not override it.

## Typed sections

Beyond free-prose standards sections, a domain file may carry three conventionally-named sections the skill consumes mechanically:

- `## deliverables` — the forms a deliverable in this domain takes, one `- {form}: {definition}` item per line. When present, the discuss verb holds the approach to naming one (`Deliverable: {form} — {name}` in the notebook's APPROACH), and the router refuses to run plan until that line exists.
- `## directives` — typed per-verb rules, one `- {verb|all}: {MUST|NEVER|GATE} {rule}` item per line. The router emits only the lines matching the running verb, last in the assembled turn, and they bind: a violated directive is a defect, not a style choice. Keep judgment guidance in prose sections; reserve directives for rules whose violation is a defect.
- `## template:{artifact}` — overrides for a verb artifact's template (`notebook`, `research`, `plan`, `execute`). Each `### {SECTION}` block replaces the same-named section of the base template, or is appended when nothing matches; the task and log-entry shapes are targets too (`### T-SHAPE` in plan, `### ENTRY-SHAPE` in execute). Overrides apply at scaffold time via `resolve-context.sh --template`; workflow overrides apply after domain overrides and win on conflict.

`## directives` and `## template:*` never emit into a turn's context — only the scope prose, standards sections, and `## deliverables` do. Authoring budget: at most 14 countable sentences per domain file (a sentence, list item, or table row each count as one; fenced reference cards introduced by one counted sentence are exempt).

A domain file may declare that it requires a companion workflow by setting `requires_workflow:` in its frontmatter:

```yaml
---
requires_workflow: writing
---

# Domain content follows …
```

When a stem selects a domain carrying `requires_workflow:`, the skill enforces the pairing at resolution time — deterministically, before the verb runs. The coupling is authoritative, not advisory. (The enforcement logic lives in `../skills/lets/scripts/resolve-context.sh`.)

The sibling dirs follow the same project→home cascade (`$PWD/.agents/…` → `~/.agents/…`): `../workflows/` holds authored workflow references, mirroring how this dir holds domain references; `../documentation/` and `../assets/` hold whatever else a domain or stem references.
