# lets

`/lets` is a small harness for thinking a piece of work through in stages, collaboratively. You steer while the LLM predicts narrowly and waits. It produces a handful of clean markdown documents that a you or LLM can pick up later and be correctly oriented — code, writing, infra decisions, research, planning, anything that benefits from being thought through before it's done.

## Concepts

### Verbs

Work moves through four verbs, in order: `discuss`, `research`, `plan`, `execute`. Each verb writes and maintains one artifact and hands off to the next. A stem doesn't have to run all four — some work stops at `discuss` and `research`, some skips straight to `plan` and `execute` — but the verbs that do run, run in order, and each one builds on what came before it.

### The stem

A **stem** is one cluster of thinking, planning, and execution toward one something. Each stem is a folder at the project root, named `{index}.{stem}` (index = the order the work began), so a root listing is the chronology of the work:

```
project-root/
  session.yml              # active stem (+ optional note)
  1.redesign-onboarding/
    notebook.md  research.md  plan.md  execute.md
  2.auth-refactor/
```

`session.yml` is the cursor: it holds the one thing that matters, which stem is active. It's human-owned — switching work is editing one line.

> **NOTE FROM THE AUTHOR**
>
> These folders live in the project root by design. In most cases folder names don't start with a number. Stem folders will always live at the top of your project root separate from the deliverables. The linear nature of generative LLMs lends itself well to this pattern. They're easy to filter with ignore rules.
>
> Stem folds do accumulate over time and it will make sense to move them all into a folder for archiving or compress them into a zip file. Tread carefully if you've got stem artifacts that reference things in other stem artifacts.
>
> In the future it might make sense to place stem folders in their own folder like `{project root}/.lets`. For now, they are where they are.

### The four artifacts

| verb       | writes        | what it is                                  |
| ---------- | ------------- | ------------------------------------------- |
| `discuss`  | `notebook.md` | the durable anchor — objective and approach |
| `research` | `research.md` | deliberate investigation grounding the work |
| `plan`     | `plan.md`     | ordered tasks toward the approach           |
| `execute`  | `execute.md`  | the work done, and a running record of it   |

The notebook anchors research, plan, and execute. They are reconciled to it when the notebook movies. A plan decomposes the notebook's approach into tasks with checklists. An execution's drift correction points back at the notebook when a task reveals the approach itself was wrong. Drop the notebook and both of those relationships lose their anchor — the rest of the harness assumes it's there.

### Living vs. ledger

Every section in every artifact is one of two kinds, and the kind is evident on sight:

- **Living** (the notebook's OBJECTIVE and APPROACH, the body of research and plan): the current understanding. Rewritten clean whenever it changes, so it always reads as the best statement of where things stand now — not a history of how it got there.
- **Ledger** (Open Questions, the execution log): append-only and chronological, with permanent sequential numbering. Nothing already written gets rewritten; a correction is a new entry, not an edit to the old one. The ledger carries the trail of how understanding got here, which frees the living prose to state only where things stand now.

### Status

Every artifact's frontmatter carries a `status:` of `active` or `locked`. The human owns it; the harness reads it and follows. `active` is the default — the artifact is open to change. `locked` freezes it: the harness leaves a locked file as is, and if a correction sweep reaches one, it stops and asks to unlock rather than writing through it.

## Quickstart

With the concepts in place, three examples show what a stem looks like in practice: a stem that runs all four verbs, a stem that stops after two, and a boundary case showing what happens with no notebook at all.

### Example (a): a stem through all four verbs

Say the work is fixing a cache invalidation bug. The stem is `3.cache-invalidation-bug`.

**`discuss`** writes `notebook.md`. OBJECTIVE names the bug; APPROACH lands on the fix once it's clear, and starts empty:

```markdown
## OBJECTIVE

Stale product prices are served after a price update; the cache isn't invalidated on write.

## APPROACH

Invalidate the price cache key on write instead of relying on TTL expiry.

## OPEN QUESTIONS

- [x] Q1: Is the write path single-writer or does it race with other updaters?
  - RESOLUTION: Single writer (the pricing service). No race to guard against.
```

**`research`** writes `research.md`, grounding the approach against the cache client and call sites before anything is planned.

**`plan`** writes `plan.md`, decomposing APPROACH into ordered tasks: add the invalidation call at the write site, remove the now-redundant TTL tuning, add a regression test.

**`execute`** writes `execute.md` — the tasks done, and a chronological log entry per finished task. The plan's checkboxes tick alongside it.

By the end, `3.cache-invalidation-bug/` holds all four artifacts, each hanging off the notebook that opened the stem.

### Example (b): a stem that stays in discuss and research

Say the work is deciding whether to move a service off SQLite. The stem is `4.evaluate-postgres-migration`.

**`discuss`** writes `notebook.md`. OBJECTIVE and APPROACH stay questions worth answering, not a fix to build:

```markdown
## OBJECTIVE

Decide whether the reporting service should move from SQLite to Postgres.

## APPROACH

Weigh the migration against the concrete problems SQLite is currently causing, not against Postgres in the abstract.

## OPEN QUESTIONS

- [ ] Q1: What write-contention errors has the service logged, and how often?
```

**`research`** writes `research.md`: current SQLite write-lock behavior, the service's concurrency pattern, and what a Postgres migration would cost in code and ops. The stem stops here — the decision this stem exists for is answered by `research.md`, and there's no approach yet concrete enough to decompose into `plan.md`.

`4.evaluate-postgres-migration/` holds `notebook.md` and `research.md`. If the decision later turns into work, `plan` and `execute` pick up from the same notebook.

### Example (c): plan + execute with no notebook

Point `/lets plan` at a stem folder with no `notebook.md`, or run `/lets execute` before one exists, and the run fails before any subagent starts. Every verb dispatches through `resolve-context.sh`, and that router requires `notebook.md` unconditionally — it locates the stem folder, then checks for the notebook and exits 1 if it's missing:

```bash
NOTEBOOK="$STEM_DIR/notebook.md"
if [[ ! -f "$NOTEBOOK" ]]; then
    echo "resolve-context: notebook.md not found at '$NOTEBOOK'" >&2
    exit 1
fi
```

That check runs ahead of the role-based content slicing and the domain/workflow resolution that follow it in the script, so it applies the same way to `plan` and `execute`, dispatcher and worker alike. There is no `/lets` command that reaches the planner or the executor without a notebook already in place.

```
project-root
  session.yml
  3.quick-fix/          # no notebook.md — resolve-context.sh exits 1 here
```

This is a boundary of the harness, not a smaller or degenerate path through it: the router has no notion of running `plan` or `execute` without a notebook to anchor them. Run `discuss` first, even briefly, to write `notebook.md` before `plan` or `execute` can run.

## Footprint

The three examples above are what `/lets` produces at a project root. The rest of this section is for maintainers: the files that make up the harness itself, and how they depend on each other.

The harness is `skills/lets/` plus a handful of files at the `.agents/` root that the skill depends on. Extracting the harness means carrying all of it.

### `skills/lets/`

| Path                         | Role                                                      |
| ---------------------------- | --------------------------------------------------------- |
| `SKILL.md`                   | Dispatcher; resolves verb/stem/artifact, hands to router. |
| `SETUP.md`                   | Authoring-mode overlay (domain/workflow setup).           |
| `reference/CORE.md`          | Shared contract prepended to every slice.                 |
| `reference/VOICE.md`         | Voice/assertion-honesty contract for prose.               |
| `verbs/discuss.md`           | Verb behavior for `discuss` (writes `notebook.md`).       |
| `verbs/research.md`          | Verb behavior for `research` (writes `research.md`).      |
| `verbs/plan.md`              | Verb behavior for `plan` (writes `plan.md`).              |
| `verbs/execute.md`           | Verb behavior for `execute` (writes `execute.md`).        |
| `templates/notebook.md`      | Template for `notebook.md`.                               |
| `templates/research.md`      | Template for `research.md`.                               |
| `templates/plan.md`          | Template for `plan.md`.                                   |
| `templates/execute.md`       | Template for `execute.md`.                                |
| `templates/domain.md`        | Template for a domain reference file.                     |
| `templates/workflow.md`      | Template for a workflow reference file.                   |
| `scripts/resolve-context.sh` | The router — assembles the caller's context slice.        |
| `scripts/read-section.sh`    | Slices one block out of a live stem document.             |

### Subagent defs — `.agents/` root

| Path            | Role                                                         |
| --------------- | ------------------------------------------------------------ |
| `executor.md`   | Implementation heavy-lifter for `/lets execute`.             |
| `planner.md`    | Decomposition heavy-lifter for `/lets plan`.                 |
| `researcher.md` | Investigation heavy-lifter for discuss and `/lets research`. |

Each carries YAML frontmatter (`name:`/`description:`/`model:`/`color:`). `install.sh` detects any root `*.md` starting with `---` and symlinks it into `$CLAUDE_HOME/agents/`.

### Shared reference — `.agents/` root

| Path                  | Role                                                            |
| --------------------- | --------------------------------------------------------------- |
| `domains/README.md`   | Explains the domain cascade mechanism; not itself a domain.     |
| `domains/coding.md`   | Domain reference: code-deliverable standards.                   |
| `domains/golang.md`   | Domain reference: Go-specific standards.                        |
| `domains/research.md` | Domain reference: research-deliverable standards.               |
| `workflows/README.md` | Explains the workflow cascade mechanism; not itself a workflow. |
| `workflows/golang.md` | Workflow preset tuning the four verbs for Go work.              |

A stem opts into a domain/workflow via `notebook.md` frontmatter; the skill resolves the name against `$PWD/.agents/<kind>/<name>.md` first, then `~/.agents/<kind>/<name>.md`. `install.sh` symlinks `domains/` and `workflows/` wholesale into `$AGENTS_HOME` (default `~/.agents/`).

Domains and workflows can be mixed and matched. The happy path is one that pairs a "writing" domain to also with a "writing" workflow. Though this is ultimately your choice

### `install.sh`

The installer for this footprint: it symlinks `executor.md`, `planner.md`, `researcher.md`, `skills/lets/`, `domains/`, and `workflows/` into `~/.claude` and `~/.agents`. An extraction needs it, or an equivalent, to stay installable.

### Dependency edges

- `SKILL.md` → `scripts/resolve-context.sh` (dispatch to router)
- `scripts/resolve-context.sh` → `reference/CORE.md` + `verbs/*.md` (+ `SETUP.md` in authoring mode)
- the skill, at each verb's dispatch → `executor.md` / `planner.md` / `researcher.md`
- the skill, via a stem's `notebook.md` frontmatter → `domains/*.md` (optional, cascading `$PWD/.agents/` then `~/.agents/`)
- the skill, via a stem's `notebook.md` frontmatter → `workflows/*.md` (optional, same cascade)
- `install.sh` → `executor.md`, `planner.md`, `researcher.md`, `skills/lets/`, `domains/`, `workflows/`
