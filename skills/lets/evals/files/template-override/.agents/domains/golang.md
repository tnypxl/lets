# Domain: Golang

Standards Go deliverables follow — the per-type reference card below binds for the project types it names; override per-project by placing a `golang.md` under the project's `.agents/domains/`.

## deliverables

- tool: a runnable CLI binary, including TUIs and agentic dispatch loops
- library: an importable module with a minimal, semver-governed public API
- service: a long-running process — HTTP, gRPC, or a background worker

## Standards

- A repo needs `go.mod` at the root and little else; `internal/` is the only layout convention the compiler enforces — don't impose a `cmd/`/`pkg/` tree as canonical, no package stutter (`chubby.File`, not `chubby.ChubbyFile`), consistent initialism case (`URL`/`url`, never `Url`), and no junk-drawer packages (`util`, `common`, `misc`).
- Prefer small, single-method interfaces named for the method with an `-er` suffix (`Reader`, `Writer`); consumers depend on the narrowest interface that does the job.
- Errors are ordinary values: check every one, return early (`if err != nil { return err }`), wrap with `fmt.Errorf("...: %w", err)`, and keep messages lowercase with no trailing punctuation.
- `context.Context` is the first parameter, named `ctx`, never stored in a struct; every goroutine's owner, lifetime, and exit condition must be obvious at the spawn site.
- Default to table-driven tests through `t.Run` with `t.Helper()` in helpers, and write doc comments as complete sentences starting with the documented name, for every exported identifier.
- `gofmt` and `go vet` are non-negotiable (plus golangci-lint where the project has it); commit `go.mod` and `go.sum` together, regenerating — never hand-editing — via `go mod tidy` or `go get`, and tag module versions as semver with a `v` prefix.

```
PER-TYPE REFERENCE CARD (binding for the matching project type)

CLI tool
  Return errors from RunE (or equivalent), never os.Exit in the command body.
  stdout = data a pipeline consumes; stderr = logs, diagnostics, progress.
  Config precedence: flags > env vars > config file > defaults (Cobra/Viper
  are the ecosystem center of gravity, not a mandate).
  Name boolean flags positively (--verbose, not --no-quiet).
  TUIs and agentic dispatch loops are CLI variants, not a separate category.

Library/package
  Minimal exported surface — when in doubt, leave it out.
  Semver on the public API; a v2+ break bumps the import path (/v2).
  Don't log-and-return internally — accept a small logger interface
  (e.g. a log/slog handler) instead of dictating output.
  Library goroutines: caller-stoppable, bounded in count.

HTTP/REST service
  Routing is unsettled: stdlib ServeMux (1.22+) or chi/gorilla — all compose
  via http.Handler, which is also how middleware chains.
  Graceful shutdown: signal.NotifyContext -> Server.Shutdown(ctx) under a
  bounded timeout.
  Shutdown only drains in-flight requests — background goroutines need their
  own WaitGroup the shutdown path waits on.

gRPC service
  The .proto file is the contract: generate via protoc/buf, never hand-edit
  generated code — regenerate on schema change.
  Cross-cutting concerns via interceptor chains (grpc.ChainUnaryInterceptor /
  ChainStreamInterceptor; go-grpc-middleware is the standard collection).
  Unary interceptors wrap one RPC; stream interceptors wrap the stream's
  lifetime — per-message logic wraps SendMsg/RecvMsg on the ServerStream.

Background worker/daemon
  Same signal.NotifyContext shutdown pattern as HTTP; drain on cancellation.
  Liveness stays healthy through the drain; readiness flips not-ready the
  instant shutdown starts.
  Bound the drain timeout inside the orchestrator's kill grace period
  (Kubernetes default: 30s).
  At-least-once delivery means idempotent handlers and backoff on retry.
```
