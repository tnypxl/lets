---
domain: golang
---

# Workflow: Golang

<!-- How the verbs behave when a stem sets `workflow: golang`. An absent
     section leaves that verb at its default; override per-project by placing
     a `golang.md` under the project's `.agents/workflows/`. -->

## plan

- Draw task boundaries at Go's seams — one outcome per package or per narrow `-er` interface, with the interface defined before its implementers so the dependency is an explicit plan edge.
- A `go.mod` change (`go get`, `go mod tidy`) is its own task sequenced before its consumers, and work reaching into an `internal/` package sequences after the task that establishes that package.

## directives

- execute: GATE `gofmt` clean, `go vet` clean, and tests passing — plus golangci-lint where the project already runs it — before any task reports done

## template:plan

### T-SHAPE
<!--
A checklist step holding one fact stays a single line. A step that bundles
more than one thing breaks into sub-bullets under that step instead of
cramming them onto one line.

### T# - {short task title}
<why this task exists within the plan — its role, not a restatement of its steps>
- [ ] Depends on: <none | T# of prerequisite tasks>
- [ ] {single-fact checklist step}
- [ ] Verify: `gofmt` clean, `go vet` clean, tests pass
-->
