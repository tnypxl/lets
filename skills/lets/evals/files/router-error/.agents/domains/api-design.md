---
requires_workflow: tdd
---

# Domain: API design

## Endpoint standards

- Every endpoint declares its response schema before implementation starts.
- Breaking changes require a new version prefix, never an in-place change.
