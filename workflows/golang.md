---
domain: golang
---

# Workflow: Golang

How the four verbs behave when a stem sets `workflow: golang`. Read as a preset when that stem runs any verb; override per-project by placing a `golang.md` under the project's `.agents/workflows/`.

The presence of a section below is the signal that this workflow shapes that verb. An absent section leaves the verb at its default. `discuss` and `research` are intentionally left at default here: research's outcome-specificity is already native to the core verb, and the one candidate tuning for discuss — nudging toward early project-type identification (CLI, library, service, worker) — is ordinary conversation, not a workflow-specific shaping.

## plan

- Draw task boundaries at Go's own seams: one outcome per package, and one per narrow `-er` interface — define the interface before its implementers so the dependency is an explicit edge in the plan, not an implicit one in the code.
- A `go.mod`/dependency change (`go get`, `go mod tidy`) is its own task, sequenced before any task that consumes the new dependency.
- `internal/` visibility is a real ordering constraint, not a style choice — the compiler enforces it, so a task that needs to reach into an `internal/` package must be sequenced after the task that establishes that package's location.
- For everything else — naming, interface shape, package layout conventions — point at the golang domain rather than restating it here.

## execute

- The completion bar for any Go task: `gofmt` clean, `go vet` clean, and tests passing. A task is not done until all three hold, regardless of how the code reads.
- These are process gates, not style prescriptions — for the *how* of formatting, vetting, and testing, defer to the domain's Tooling and Testing sections.
- Where a project runs golangci-lint, its passing is folded into the same completion bar; this workflow does not mandate adopting it.

> `plan` and `execute` are the only verbs tuned here — the shape above is recommended taste, enforced by nothing. Add `discuss` or `research` sections, or restructure what's here, as your own Go conventions diverge from these.
