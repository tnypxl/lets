# Workflows

Workflow references are optional, read-only presets for a stem. A stem opts in by setting `workflow: <name>` in its `notebook.md` frontmatter; `/lets` then resolves `<name>.md` against a cascade and reads the first hit when shaping how the four verbs behave:

```
$PWD/.agents/workflows/<name>.md          # project override — wins
~/.agents/workflows/<name>.md             # the default floor (~/.agents/ is typically a symlink into the dotfiles tree)
```

A project overrides the default by placing its own `<name>.md`; the files here are the floor. A workflow is a *preset that tunes the four verbs* — a default domain plus one prose guidance section per verb it shapes. The skill reads these; it never writes them.

## Verb sections as signal

The presence of a `## discuss`, `## research`, `## plan`, or `## execute` section in a workflow file is the signal that the workflow shapes that verb; an absent section leaves that verb at its default. There is no separate `stages` list — a parallel enumeration would be a second source of truth and would drift from the sections themselves. Body structure beyond this convention is recommended taste, enforced by nothing. On any given turn the router emits only the running verb's section (plus any non-verb prose), so guidance for one verb never spends another verb's budget.

## Typed sections

A workflow file may also carry two conventionally-named sections the skill consumes mechanically:

- `## directives` — typed per-verb rules, one `- {verb|all}: {MUST|NEVER|GATE} {rule}` item per line. The router emits only the lines matching the running verb, last in the assembled turn, and they bind: a violated directive is a defect, not a style choice. This is where hard completion gates live (see `golang.md`); keep judgment guidance in the per-verb prose sections.
- `## template:{artifact}` — overrides for a verb artifact's template (`notebook`, `research`, `plan`, `execute`). Each `### {SECTION}` block replaces the same-named section of the base template, or is appended when nothing matches; the task and log-entry shapes are targets too (`### T-SHAPE` in plan, `### ENTRY-SHAPE` in execute). Overrides apply at scaffold time via `resolve-context.sh --template`; workflow overrides apply after domain overrides and win on conflict.

Neither section ever emits into a turn's context. Authoring budget: at most 10 countable sentences per workflow file (a sentence, list item, or table row each count as one).

## Frontmatter

A workflow file may carry frontmatter to preset a domain and declare a required companion:

```yaml
---
domain: writing
requires_domain: writing
---

# Workflow content follows …
```

`domain:` sets the default domain the workflow presets — a stem that selects this workflow inherits that domain unless its notebook overrides it. `requires_domain:` declares that the workflow must be paired with a specific domain; when a stem selects a workflow carrying `requires_domain:`, the skill enforces the pairing at resolution time — deterministically, before the verb runs. The coupling is authoritative, not advisory. (The enforcement logic lives in `../skills/lets/scripts/resolve-context.sh`.)

The sibling dirs follow the same project→home cascade (`$PWD/.agents/…` → `~/.agents/…`): `../domains/` holds domain references, mirroring how this dir holds workflow references; `../documentation/` and `../assets/` hold whatever else a domain or stem references.
