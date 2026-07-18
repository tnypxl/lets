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

## execute

- The completion bar for any Go task: `gofmt` clean, `go vet` clean, tests passing — plus golangci-lint passing where the project already runs it.
- These are process gates, not style prescriptions; for the *how*, defer to the domain.
