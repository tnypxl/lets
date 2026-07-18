# Domain: Coding

<!-- Read as context when a stem sets `domain: coding`; override per-project
     by placing a `coding.md` under the project's `.agents/domains/`. -->

## deliverables

- change: a working change to an existing codebase, verified by the project's own checks
- fix: the smallest change that corrects a diagnosed defect
- review: findings on existing code, each anchored to a file and line

## Standards

- Match the surrounding code's conventions, naming, comment density, and idioms — code should read like the code already there, not like it was generated.
- Prefer the smallest clear solution: 50 clear lines beat 200 flexible ones — no speculative abstraction, no wrapper that wraps once, no dead code.
- Name everything for what it is in its own domain; surface failure modes, never swallow errors.
- Comment only the non-obvious — a constraint, a decision, a sharp edge — not what the code already says.
- Follow the repository's existing layout and module boundaries; discover the convention before adding to it.
- Tests live where the project keeps them and follow its existing patterns.

## directives

- execute: MUST run the project's own checks (build, tests, linters) before any task reports done
