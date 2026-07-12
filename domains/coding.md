# Domain: Coding

Standards that software deliverables in this domain follow. Read as context when a stem sets `domain: coding`; override per-project by placing a `coding.md` under the project's `.agents/domains/`.

## Code

- Match the surrounding code's conventions, naming, comment density, and idioms. Code should read like the code already there, not like it was generated.
- Prefer the smallest clear solution. 50 clear lines beat 200 flexible ones. No speculative abstraction, no wrapper that wraps once, no dead code.
- Name everything for what it is in its own domain. Surface failure modes; never swallow errors.
- Comment only the non-obvious — a constraint, a decision, a sharp edge. Not what the code already says.

## Structure

- Follow the repository's existing layout and module boundaries. Discover the convention before adding to it.
- Tests live where the project keeps them and follow its existing patterns.

## Deliverable hygiene

- Nothing shipped carries harness vocabulary — no task or question identifiers, no phase names, no workflow terms in names, comments, commits, or logs. (See `../skills/lets/reference/CORE.md` § Voice.)
- Commit messages describe the change in the project's own terms.

> This is a starter floor. Tend it to your defaults — preferred languages, frameworks, lint/format rules, review bar.
