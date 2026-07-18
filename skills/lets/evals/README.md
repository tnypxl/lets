# Evals for the lets harness

Two layers verify the harness. Deterministic script behavior is tested by
`../tests/test-scripts.sh` and the budget gate `../scripts/check-budget.sh`;
model behavior — does an agent running the skill obey the harness — is
tested by the evals in `evals.json` (skill-creator format). Run order:

```sh
bash skills/lets/tests/test-scripts.sh
bash skills/lets/scripts/check-budget.sh
# then the model evals below
```

## What the model evals care about

Each eval targets one rule the harness depends on:

| id | name | rule under test |
|----|------|-----------------|
| 1 | cold-start-scaffold | session/stem/notebook scaffolding, router-first, turn cadence |
| 2 | unknown-verb-stops | unrecognized verb → ask and stop, no side effects |
| 3 | discuss-ledger-discipline | Q# ledger append-only, resolution format, no renumbering |
| 4 | plan-flow-contracts | bounded task contract, planner returns unnumbered candidates, skill assigns T#, metering |
| 5 | plan-tnumber-permanence | T# never reassigned; continuation appends from the next number |
| 6 | execute-flow-writer-separation | executor writes external artifacts only; skill writes log + tick; vocabulary non-leak |
| 7 | locked-artifact-refusal | `status: locked` → read-only stop |
| 8 | router-error-verbatim | router stderr surfaced verbatim, stop, no silent repair |
| 9 | research-flow-metered | researcher output contract, metered write-in, no invented sources |
| 10 | drift-stop-and-flag | drift is stop-and-flag, never patched over; ledger untouched |
| 11 | setup-mode-redirect | setup mode redirects the deliverable to `.agents/`, vocabulary rule inverts |
| 12 | next-index-creation | new stem gets highest index + 1; existing stems untouched |

## Running an eval

The skill-creator runner is agentic, so the workspace convention lives here:

1. `work=$(mktemp -d)`; copy the eval's fixture into it:
   `cp -R skills/lets/evals/files/<name>/. "$work"/` (evals 1 and 2 start
   from an empty directory). The `evals/files/<name>/` prefix maps to the
   workspace root — a fixture's `session.yml` lands at `$work/session.yml`.
2. Install the skill: `mkdir -p "$work/.claude/skills" && cp -R skills/lets
   "$work/.claude/skills/lets"`. Verify `scripts/*.sh` stayed executable.
3. Install the workflow agents: `mkdir -p "$work/.claude/agents" && cp
   skills/lets/evals/files/_agents/*.md "$work/.claude/agents/"`. These are
   snapshots of the repo-root `planner.md` / `executor.md` / `researcher.md`;
   refresh them when the originals change.
4. Run the eval prompt as a session rooted at `$work` and capture the
   transcript. Evals 4-6 and 9-11 spawn subagents; if the runner executes
   evals inside a subagent that cannot itself spawn subagents, run those
   evals as top-level `claude -p` sessions in `$work` instead.
5. Grade each expectation against the transcript plus the final workspace,
   comparing against the fixture copy still in `evals/files/<name>/`.

## Grading notes

Prefer scripts over eyeballing wherever an expectation allows it:

- Existence and frontmatter: `test -f`, `grep '^status:'`.
- Append-only ledgers (3, 5, 6, 10, 12): every fixture line must survive —
  `git diff --no-index <fixture> <result>` should show additions only, or
  byte-identity where the eval demands it (`cmp`).
- Numbering (3, 4, 5, 6): `grep -oE '^### T[0-9]+' plan.md` must be a
  gap-free ascending sequence; every `### T# -` in execute.md needs a
  matching plan heading; highest Q# checks likewise.
- Behavior (6): actually run `bash greet.sh --shout alice`.
- Vocabulary leak (6): `grep -E '\bT[0-9]+\b|\bQ[0-9]+\b|\bstem\b|notebook\.md'`
  over external artifacts must be empty.
- Universal sanity for any eval that ends with a live stem: rerun
  `resolve-context.sh --activity discuss --role dispatcher` from the
  workspace; exit 0 means the agent left a coherent session/stem/notebook.

## Known risks

- Hermeticity: on a machine where lets is installed user-level
  (`~/.claude/skills/lets`), the installed copy can shadow the workspace
  copy, so the run grades the installed version — possibly stale — instead
  of the checkout. For hermetic runs, point the session at an isolated
  config (scratch `HOME`/`CLAUDE_CONFIG_DIR`) or uninstall first, and
  confirm in the transcript that script paths resolve inside the workspace.

- Subagent spawning inside a nested eval executor is the main structural
  risk; smoke-test eval 1 and one subagent eval (4 or 6) before trusting a
  full run.
- Eval 10 (drift) is flaky by design — it needs the executor to notice the
  contradiction and the dispatcher to stop. A moderate pass rate is
  expected; the signal is still worth it.
- Metering expectations (4, 9) are conditional: a small return written in
  full is compliant.
- Prose quality is not graded pass/fail; only the mechanical vocabulary
  grep stands in for the voice rules.
