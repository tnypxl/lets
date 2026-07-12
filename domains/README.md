# Domains

Domain references are optional, read-only context for a stem. A stem opts in by setting `domain: <name>` in its `notebook.md` frontmatter; `/lets` then resolves `<name>.md` against a cascade and reads the first hit when shaping deliverables (code style, citation format, document structure, naming conventions):

```
$PWD/.agents/domains/<name>.md          # project override — wins
~/.agents/domains/<name>.md             # the default floor (~/.agents/ is typically a symlink into the dotfiles tree)
```

A project overrides the default by placing its own `<name>.md`; the files here are the floor. A reference describes the *standards a domain's deliverables follow* — not the work itself, and not the harness. The skill reads these; it never writes them.

Prose deliverables carry a separate, standing voice baseline from `../skills/lets/reference/VOICE.md`, which applies whether or not a stem selects a domain. A selected domain adds standards on top of that baseline; it does not override it.

A domain file may declare that it requires a companion workflow by setting `requires_workflow:` in its frontmatter:

```yaml
---
requires_workflow: writing
---

# Domain content follows …
```

When a stem selects a domain carrying `requires_workflow:`, the skill enforces the pairing at resolution time — deterministically, before the verb runs. The coupling is authoritative, not advisory. (The enforcement logic lives in `../skills/lets/scripts/resolve-context.sh`.)

The sibling dirs follow the same project→home cascade (`$PWD/.agents/…` → `~/.agents/…`): `../workflows/` holds authored workflow references, mirroring how this dir holds domain references; `../documentation/` and `../assets/` hold whatever else a domain or stem references.
