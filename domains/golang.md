# Domain: Golang

Standards that Go programming and project development follow, project-agnostic and global; override per-project by placing a `golang.md` under the project's `.agents/domains/`.

## Package & project structure

- There is no single official Go project layout. `golang-standards/project-layout` is a popular community convention, not a Go-team standard — Russ Cox pushed back on it directly (golang-standards/project-layout#117), calling it too complex and objecting to the "standard" framing as misleading to newcomers.
- The Go team's actual minimal position: a repo needs a `LICENSE`, a `go.mod` at the root, and code organized however the author sees fit. Nothing more is required.
- `internal/` is the one layout convention the compiler enforces — packages under it are import-restricted to the module tree rooted at its parent. Treat it as load-bearing.
- `cmd/` and `pkg/` are conventional, not enforced — useful shorthand some projects adopt, not a tree to impose by default.
- Do not prescribe a `cmd/`/`pkg/`/`internal/` tree as if it were canonical; describe what's real (the enforced part and the floor) rather than recommending a fixed shape.

## Naming & API design

- No stutter: a type's name should not repeat its package. Callers already write the package prefix, so `chubby.ChubbyFile` is redundant — `chubby.File` is the exported name, referenced as `chubby.File` from outside the package.
- Avoid junk-drawer package names like `util`, `common`, or `misc`. A package name should describe what it provides, not that it's a place things got put.
- Keep initialism case consistent: an initialism is all-caps or all-lowercase, never mixed — `URL`/`url`, not `Url`; `ID`/`id`, not `Id`.
- Scale name length with scope: short, even single-letter names are fine for tight, short-lived scopes (loop indices, a receiver named `f` on a small method); names visible across a package or exported outward need to carry enough meaning to stand alone.
- Prefer small, single-method interfaces named for the method with an `-er` suffix — `Reader`, `Writer`, `Closer` — over large multi-method interfaces. Consumers should depend on the narrowest interface that does the job.

## Errors

- An error is an ordinary returned value, not an exception — never discard one with `_`; if a call can fail, check it.
- Error message strings are lowercase and carry no trailing punctuation, since they routinely get wrapped into larger messages further up the call stack.
- Follow the naming convention: local variables holding an error are `err`; exported sentinel errors are `Err`-prefixed (`ErrNotFound`); exported error types are `-Error`-suffixed (`ParseError`).
- Handle and return immediately — `if err != nil { return err }` — rather than nesting the success path inside an else-block; the happy path stays unindented.
- Wrap with `fmt.Errorf("...: %w", err)` to add context and preserve the chain, but don't repeat what the wrapped error already says.

## Concurrency

- `context.Context` is a function's first parameter, conventionally named `ctx` — never store one in a struct field.
- Whoever creates a cancelable context owns calling its `CancelFunc`; failing to call it leaks the context and whatever it's tracking.
- Context values carry request-scoped data across API boundaries only — not a channel for passing optional or function-scoped parameters.
- Every goroutine's lifetime and exit condition must be obvious from the code that spawns it; a goroutine with no clear stop signal is a leak waiting to happen.

## Testing

- Default to table-driven tests: a slice of case structs (name, inputs, expected outcome) driven through a loop that calls `t.Run(tt.name, ...)` per case, so failures report which case and cases can run in isolation.
- Call `t.Helper()` at the top of test helper functions so a failing assertion's line number points at the caller, not at the helper itself.
- Use `Example` functions (with a `// Output:` comment) as compiler-checked documentation — they're verified by `go test` and shown to readers as usage examples, doing double duty.
- Whether to pull in an assertion library like testify or stick to stdlib (`if got != want { t.Errorf(...) }`) is a contested, project-level choice, not a settled convention — both are idiomatic; don't default to one without checking what the project already uses.

## Tooling & dependencies

- Format every file with gofmt; there is no style debate to have — unformatted Go code is simply wrong.
- Run `go vet` to catch code that compiles but misbehaves — suspicious constructs like malformed format-string arguments or unreachable code, not style.
- Reach for golangci-lint as the standard aggregator that runs many linters (including vet) together under one config, rather than wiring each linter up separately.
- Commit both `go.mod` and `go.sum`; never hand-edit `go.sum` — regenerate it via `go mod tidy` or `go get` when dependencies change.
- Tag and reference module versions with semver and a `v` prefix (`v1.2.3`).
- Vendoring (`vendor/`) is situational, adopted when build reproducibility demands it — not a default practice.

## Documentation

- Write doc comments as complete sentences that start with the name of the thing they document — `// File represents an open file descriptor.` — since `go doc` and godoc render them verbatim, name first.
- Place the package doc comment directly above the `package` clause with no blank line between them; a blank line breaks the association and tools stop treating it as the package comment.
- Document every exported identifier — const, var, func, type, and method — even briefly; an undocumented exported name is a gap style linters commonly flag.

## Per-type: CLI tool

- Return errors from a command's `RunE` (or equivalent) rather than calling `os.Exit` inside the command body — that keeps the error path testable and composable and leaves the exit code decision to the top-level entrypoint.
- stdout carries the command's data output, the part a pipeline would consume; stderr carries logs, diagnostics, and progress. Keep the two separate; mixing them breaks piping.
- Configuration precedence runs flags > environment variables > config file > defaults. Cobra (command structure) and Viper (config layering) are the ecosystem's center of gravity for this pattern, not a mandate to use them.
- Name boolean flags positively (`--verbose`, not `--no-quiet`) so usage doesn't require untangling a double negative.
- A TUI's event loop and an agentic tool-call dispatch loop are the same shape as a CLI's command loop wearing a different front end — treat both as CLI variants, not a separate project-type category.

## Per-type: Library/package

- Keep the exported surface minimal — when in doubt, leave it out. Anything exported is a permanent commitment; unexported defaults keep options open.
- Follow semver for the module's public API; a v2+ breaking change requires bumping the import path with a `/v2` suffix, since Go's module system treats different major versions as different import paths, not just different tags.
- Don't log-and-return errors internally — accept a small logger interface (a `log/slog` handler, or one the caller can satisfy with their own logger) rather than dictating how or where output goes.
- Any goroutine a library spawns must be caller-stoppable and bounded in count — never scale goroutine count unbounded with input size, and never leave a library-owned goroutine with no way for the caller to stop it.

## Per-type: HTTP/REST service

- Routing is a landscape, not a settled choice: stdlib `net/http`'s `ServeMux` supports method- and pattern-based routing directly (Go 1.22+), while third-party routers like chi or gorilla/mux add features some projects want. Both compose through the standard `http.Handler` interface, which is how middleware chains regardless of router choice.
- Shut down gracefully: use `signal.NotifyContext` to turn an incoming termination signal into a cancelable `context.Context`, then on cancellation call `Server.Shutdown(ctx)` under a bounded timeout so requests already in flight get a chance to finish before the process exits.
- `Server.Shutdown` only drains in-flight HTTP requests — it has no visibility into background goroutines the service spawned (workers, pollers, consumers). Those need their own `sync.WaitGroup` (or equivalent) that the shutdown path waits on explicitly; `Shutdown` returning does not mean they've stopped.

## Per-type: gRPC service

- The `.proto` file is the contract: service and message definitions live there, and the Go interfaces and structs are generated from it via `protoc` or `buf` — never hand-written to match, and never hand-edited afterward; regenerate on schema change the same way `go.sum` gets regenerated rather than patched.
- Handle cross-cutting concerns (auth, logging, panic recovery) with interceptor chains — `grpc.ChainUnaryInterceptor`/`grpc.ChainStreamInterceptor` — rather than duplicating that logic in every handler; go-grpc-middleware is the ecosystem's standard collection of these interceptors.
- A unary interceptor runs once per RPC call, wrapping the single request/response. A stream interceptor wraps the entire stream's lifetime instead, so acting on individual messages within it requires wrapping the `grpc.ServerStream`'s `SendMsg`/`RecvMsg` methods, not just the interceptor entry point.

## Per-type: Background worker/daemon

- Shut down on the same `signal.NotifyContext` pattern as the HTTP service section above: turn the termination signal into a cancelable `context.Context` and drain in-flight work on cancellation rather than inventing a separate mechanism.
- Split liveness from readiness: liveness stays healthy through the drain period — the process is still alive and finishing work, so killing it early would cut that work off mid-flight. Readiness flips to not-ready the instant the shutdown signal arrives, so the orchestrator stops routing new work to a process that's already winding down.
- Bound the drain timeout comfortably inside the orchestrator's kill grace period — Kubernetes defaults to 30 seconds before sending SIGKILL — or in-flight work gets killed anyway once the grace period expires, regardless of how the drain was written.
- Handlers should be idempotent and retries should back off rather than retry immediately: at-least-once delivery, common with queue- or pubsub-backed workers, means a handler can run more than once for the same message. Treat both as established convention for this kind of worker, not something to derive from scratch per project.

## Deliverable hygiene

- Shipped Go code carries no harness vocabulary — no task or question identifiers, no phase names, no workflow terms in package names, identifiers, comments, commit messages, or logs.
- Name packages, types, and functions for what they do in their own domain, not for the process that produced them.
- Commit messages describe the change in the project's own terms.

> This is a starter floor. Tend it to your defaults — linters, module layout, preferred frameworks per project type, review bar.
