#!/usr/bin/env bash
# Deterministic contract tests for resolve-context.sh and read-section.sh.
# Builds throwaway fixture projects under mktemp -d and asserts on exit
# codes, stderr messages, and output shape. Run from anywhere:
#   bash skills/lets/tests/test-scripts.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
RC="$SKILL_DIR/scripts/resolve-context.sh"
RS="$SKILL_DIR/scripts/read-section.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME"

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n    %s\n' "$1" "$2"; }

# run <cwd> <cmd...> — captures stdout/stderr/exit into globals.
run() {
    local cwd="$1"; shift
    OUT="$(cd "$cwd" && HOME="$FAKE_HOME" "$@" 2>"$TMP/stderr")"
    RCODE=$?
    ERR="$(cat "$TMP/stderr")"
}

assert_fails_with() {  # <name> <stderr-substring>
    local name="$1" want="$2"
    if [[ $RCODE -eq 0 ]]; then bad "$name" "expected nonzero exit, got 0"
    elif [[ "$ERR" != *"$want"* ]]; then bad "$name" "stderr missing '$want'; got: $ERR"
    else ok "$name"; fi
}

assert_ok_contains() {  # <name> <stdout-substring>...
    local name="$1"; shift
    if [[ $RCODE -ne 0 ]]; then bad "$name" "expected exit 0, got $RCODE; stderr: $ERR"; return; fi
    local want
    for want in "$@"; do
        if [[ "$OUT" != *"$want"* ]]; then bad "$name" "stdout missing '$want'"; return; fi
    done
    ok "$name"
}

assert_not_contains() {  # <name> <stdout-substring>...
    local name="$1"; shift
    local want
    for want in "$@"; do
        if [[ "$OUT" == *"$want"* ]]; then bad "$name" "stdout unexpectedly contains '$want'"; return; fi
    done
    ok "$name"
}

# new_proj <name> <stem> — fresh project with session.yml + stem folder + notebook.
# Prints the project path.
new_proj() {
    local proj="$TMP/$1" stem="$2"
    mkdir -p "$proj/1.$stem"
    printf 'stem: %s\n' "$stem" > "$proj/session.yml"
    cat > "$proj/1.$stem/notebook.md" <<'EOF'
---
title: fixture
status: active
---

## OBJECTIVE

A fixture objective.

## APPROACH

## OPEN QUESTIONS
EOF
    echo "$proj"
}

echo "resolve-context.sh — flag validation"
EMPTY="$TMP/empty"; mkdir -p "$EMPTY"

run "$EMPTY" "$RC"
assert_fails_with "missing --activity" "--activity is required"

run "$EMPTY" "$RC" --activity deploy
assert_fails_with "bad --activity" "must be one of discuss|research|plan|execute"

run "$EMPTY" "$RC" --activity plan --role manager
assert_fails_with "bad --role" "--role must be one of dispatcher|worker"

run "$EMPTY" "$RC" --activity plan --mode turbo
assert_fails_with "bad --mode" "--mode must be one of full|inline"

run "$EMPTY" "$RC" --activity plan --setup domain
assert_fails_with "--setup retired" "unrecognized argument '--setup'"

run "$EMPTY" "$RC" --activity setup
assert_fails_with "setup requires --kind" "requires --kind"

run "$EMPTY" "$RC" --activity setup --kind verb --name x
assert_fails_with "bad --kind" "--kind must be one of domain|workflow"

run "$EMPTY" "$RC" --activity setup --kind domain
assert_fails_with "setup requires --name" "requires --name"

run "$EMPTY" "$RC" --activity setup --kind domain --name 'bad name!'
assert_fails_with "bad --name" "--name must be letters, digits, dashes, underscores"

run "$EMPTY" "$RC" --activity plan --kind domain --name x
assert_fails_with "--kind rejected outside setup" "apply only to --activity setup"

run "$EMPTY" "$RC" --activity plan --bogus x
assert_fails_with "unrecognized argument" "unrecognized argument '--bogus'"

echo "resolve-context.sh — session/stem resolution"
run "$EMPTY" "$RC" --activity discuss
assert_fails_with "no session.yml" "no session.yml found"

run "$SKILL_DIR" "$RC" --activity discuss
assert_fails_with "cwd inside skill dir refused" "never cd into the skill"

run "$SKILL_DIR/scripts" "$RC" --activity plan --template
assert_fails_with "skill-dir guard covers subdirs and --template" "never cd into the skill"

# A .git boundary without session.yml stops the walk — the outer stray
# session.yml above the repo must not be silently adopted.
BOUND="$TMP/bound"; mkdir -p "$BOUND/inner/src" "$BOUND/inner/.git"
printf 'stem: stray\n' > "$BOUND/session.yml"
run "$BOUND/inner/src" "$RC" --activity discuss
assert_fails_with "walk stops at repo boundary" "not searching above it"

# But a project subdir with no boundary in between still resolves upward.
SUBP="$(new_proj subp deep)"; mkdir -p "$SUBP/1.deep/nested"
run "$SUBP/1.deep/nested" "$RC" --activity discuss
assert_ok_contains "subdir resolves to project root" "<lets_context activity=\"discuss\""

NOSTEM="$TMP/nostem"; mkdir -p "$NOSTEM"
printf 'note: hi\n' > "$NOSTEM/session.yml"
run "$NOSTEM" "$RC" --activity discuss
assert_fails_with "empty stem key" "'stem:' is missing or empty"

NOFOLDER="$TMP/nofolder"; mkdir -p "$NOFOLDER"
printf 'stem: ghost\n' > "$NOFOLDER/session.yml"
run "$NOFOLDER" "$RC" --activity discuss
assert_fails_with "missing stem folder" "no stem folder matching '*.ghost'"

NONB="$TMP/nonb"; mkdir -p "$NONB/1.bare"
printf 'stem: bare\n' > "$NONB/session.yml"
run "$NONB" "$RC" --activity plan
assert_fails_with "missing notebook.md" "notebook.md not found"

echo "resolve-context.sh — assembly shape"
P="$(new_proj shape alpha)"
run "$P" "$RC" --activity discuss
assert_ok_contains "discuss dispatcher assembles" \
    '<lets_context activity="discuss" role="dispatcher">' \
    '<core>' '<verb name="discuss">' '</lets_context>'
run "$P" "$RC" --activity discuss
assert_not_contains "no selectors -> no domain/workflow segments" '<domain' '<workflow'
run "$P" "$RC" --activity discuss
assert_not_contains "no skill paths leak into output" "$SKILL_DIR"
run "$P" "$RC" --activity discuss
assert_not_contains "role fences stripped" '<!-- role:'

run "$P" "$RC" --activity plan --role dispatcher
DISPATCHER_OUT="$OUT"
run "$P" "$RC" --activity plan --role worker
if [[ $RCODE -eq 0 && "$OUT" != "$DISPATCHER_OUT" && "$OUT" == *'role="worker"'* ]]; then
    ok "plan worker slice differs from dispatcher slice"
else
    bad "plan worker slice differs from dispatcher slice" "exit=$RCODE"
fi

run "$P" "$RC" --activity research --mode inline
assert_ok_contains "mode attr carried on root" 'mode="inline"'

echo "resolve-context.sh — domain/workflow cascade and precedence"
mkdomain() {  # <dir> <name> <marker> [frontmatter-line]...
    local dir="$1" name="$2" marker="$3"; shift 3
    mkdir -p "$dir"
    { echo '---'; for l in "$@"; do echo "$l"; done; echo '---'; echo "# Domain: $name"; echo "$marker"; } \
        > "$dir/$name.md"
}
mkworkflow() {  # <dir> <name> <marker> [frontmatter-line]...
    local dir="$1" name="$2" marker="$3"; shift 3
    mkdir -p "$dir"
    { echo '---'; for l in "$@"; do echo "$l"; done; echo '---'; echo "# Workflow: $name"; echo "$marker"; } \
        > "$dir/$name.md"
}

P="$(new_proj cascade beta)"
printf 'stem: beta\ndomain: styles\n' > "$P/session.yml"
mkdomain "$P/.agents/domains" styles "PROJECT-COPY"
mkdomain "$FAKE_HOME/.agents/domains" styles "HOME-COPY" "front_marker: fm-should-be-stripped"
run "$P" "$RC" --activity discuss
assert_ok_contains "project .agents wins cascade" '<domain name="styles">' "PROJECT-COPY"
run "$P" "$RC" --activity discuss
assert_not_contains "home copy not used when project copy exists" "HOME-COPY"

rm -rf "$P/.agents"
run "$P" "$RC" --activity discuss
assert_ok_contains "home .agents is the cascade floor" "HOME-COPY"
run "$P" "$RC" --activity discuss
assert_not_contains "domain frontmatter stripped" 'fm-should-be-stripped'

printf 'stem: beta\ndomain: nonexistent\n' > "$P/session.yml"
run "$P" "$RC" --activity discuss
assert_fails_with "unresolvable domain" "domain 'nonexistent' not found in cascade"

P="$(new_proj precedence gamma)"
mkdomain "$P/.agents/domains" nb-dom "FROM-NOTEBOOK"
mkdomain "$P/.agents/domains" wf-dom "FROM-WORKFLOW-PRESET"
mkdomain "$P/.agents/domains" sess-dom "FROM-SESSION"
mkworkflow "$P/.agents/workflows" flow "WF-BODY" "domain: wf-dom"

printf 'stem: gamma\ndomain: sess-dom\nworkflow: flow\n' > "$P/session.yml"
cat > "$P/1.gamma/notebook.md" <<'EOF'
---
status: active
domain: nb-dom
---
## OBJECTIVE
EOF
run "$P" "$RC" --activity discuss
assert_ok_contains "notebook domain beats preset and session" '<domain name="nb-dom">'

cat > "$P/1.gamma/notebook.md" <<'EOF'
---
status: active
---
## OBJECTIVE
EOF
run "$P" "$RC" --activity discuss
assert_ok_contains "workflow preset beats session domain" '<domain name="wf-dom">' '<workflow name="flow">'

printf 'stem: gamma\ndomain: sess-dom\n' > "$P/session.yml"
run "$P" "$RC" --activity discuss
assert_ok_contains "session domain used when nothing above it" '<domain name="sess-dom">'

echo "resolve-context.sh — coupling enforcement"
P="$(new_proj coupling delta)"
mkdomain "$P/.agents/domains" strict "STRICT-DOM" "requires_workflow: tdd"
printf 'stem: delta\ndomain: strict\n' > "$P/session.yml"
run "$P" "$RC" --activity discuss
assert_fails_with "domain requires_workflow unmet" "domain 'strict' requires workflow 'tdd'"

mkworkflow "$P/.agents/workflows" tdd "TDD-WF" "requires_domain: strict"
printf 'stem: delta\ndomain: strict\nworkflow: tdd\n' > "$P/session.yml"
run "$P" "$RC" --activity discuss
assert_ok_contains "satisfied coupling passes" '<domain name="strict">' '<workflow name="tdd">'

mkworkflow "$P/.agents/workflows" lone "LONE-WF" "requires_domain: strict"
printf 'stem: delta\nworkflow: lone\n' > "$P/session.yml"
run "$P" "$RC" --activity discuss
assert_fails_with "workflow requires_domain unmet" "workflow 'lone' requires domain 'strict'"

echo "resolve-context.sh — directives, deliverables, template overrides"
P="$(new_proj typed zeta)"
mkdir -p "$P/.agents/domains" "$P/.agents/workflows"
cat > "$P/.agents/domains/writing.md" <<'EOF'
# Domain: writing
Scope prose.

## deliverables
- chapter: a full draft chapter
- outline: a chapter-level outline

## style
- One idea per paragraph.

## directives
- discuss: MUST surface the audience first
- plan: NEVER split one chapter across tasks
- all: MUST keep register consistent

## template:plan
### T-SHAPE
DOMAIN-TASK-SHAPE

### VOICE NOTES
DOMAIN-VOICE-BODY
EOF
cat > "$P/.agents/workflows/book.md" <<'EOF'
---
domain: writing
---
# Workflow: book

## plan
Chapters ordered by narrative dependency.

## directives
- plan: MUST order tasks by narrative dependency

## template:plan
### VOICE NOTES
WORKFLOW-VOICE-BODY
EOF
printf 'stem: zeta\nworkflow: book\n' > "$P/session.yml"

run "$P" "$RC" --activity discuss
assert_ok_contains "discuss directives sliced (discuss + all)" \
    '<directives binding="true" activity="discuss">' \
    '[domain:writing] MUST surface the audience first' \
    '[domain:writing] MUST keep register consistent'
run "$P" "$RC" --activity discuss
assert_not_contains "other-verb directives excluded from discuss" \
    'NEVER split one chapter' 'order tasks by narrative dependency'
run "$P" "$RC" --activity discuss
assert_not_contains "meta sections stripped from reference segments" \
    '## directives' '## template:' 'DOMAIN-TASK-SHAPE' 'WORKFLOW-VOICE-BODY'
run "$P" "$RC" --activity discuss
if [[ $RCODE -eq 0 && "$OUT" == *'</directives>

</lets_context>'* ]]; then
    ok "directives segment emitted last"
else
    bad "directives segment emitted last" "exit=$RCODE; tail: ${OUT: -120}"
fi
run "$P" "$RC" --activity discuss
assert_ok_contains "deliverable GATE generated on discuss" \
    "GATE the APPROACH is not committable" "one of: chapter, outline"
run "$P" "$RC" --activity discuss
assert_not_contains "other-verb workflow sections excluded from discuss" \
    'Chapters ordered by narrative dependency'

run "$P" "$RC" --activity plan
assert_fails_with "plan blocked without Deliverable line" \
    "defines deliverable forms, but the notebook APPROACH names none"

cat > "$P/1.zeta/notebook.md" <<'EOF'
---
title: fixture
status: active
---

## OBJECTIVE

## APPROACH

Deliverable: chapter — the opening chapter.

## OPEN QUESTIONS
EOF
run "$P" "$RC" --activity plan
assert_ok_contains "plan passes with Deliverable line" \
    '<directives binding="true" activity="plan">' \
    '[domain:writing] NEVER split one chapter across tasks' \
    '[workflow:book] MUST order tasks by narrative dependency'
run "$P" "$RC" --activity plan
assert_ok_contains "matching workflow section emitted on its verb" \
    'Chapters ordered by narrative dependency'

run "$P" "$RC" --activity plan --template
assert_ok_contains "template mode appends unmatched override sections" \
    '## OVERVIEW' '## TASKS' '## VOICE NOTES'
run "$P" "$RC" --activity plan --template
if [[ $RCODE -eq 0 && "$OUT" == *'WORKFLOW-VOICE-BODY'* && "$OUT" != *'DOMAIN-VOICE-BODY'* ]]; then
    ok "workflow override beats domain override"
else
    bad "workflow override beats domain override" "exit=$RCODE"
fi
run "$P" "$RC" --activity plan --template
assert_not_contains "template mode prints no context document" '<lets_context'

cat > "$P/.agents/domains/anchored.md" <<'EOF'
# Domain: anchored

## template:plan
### TASKS
REPLACED-TASKS-BODY
EOF
printf 'stem: zeta\ndomain: anchored\n' > "$P/session.yml"
run "$P" "$RC" --activity plan --template
if [[ $RCODE -eq 0 && "$OUT" == *'REPLACED-TASKS-BODY'* && "$OUT" != *'stable anchor shared with the execute log'* ]]; then
    ok "matching override replaces the base section body"
else
    bad "matching override replaces the base section body" "exit=$RCODE"
fi

rm -rf "$P/1.zeta"
run "$P" "$RC" --activity discuss --template
assert_ok_contains "template mode tolerates missing stem folder" '## OBJECTIVE' '## APPROACH'
run "$P" "$RC" --activity discuss
assert_fails_with "non-template call still requires the stem folder" "no stem folder matching"

echo "resolve-context.sh — setup flow"
run "$EMPTY" "$RC" --activity setup --kind domain --name python-style
assert_ok_contains "setup emits flow, template, no stem needed" \
    '<lets_context activity="setup" kind="domain" name="python-style">' \
    '<setup kind="domain" name="python-style">' \
    '<template kind="domain">' \
    '## interview'
run "$EMPTY" "$RC" --activity setup --kind domain --name python-style
assert_not_contains "setup emits no verb/domain/workflow segments" \
    '<verb name=' '<domain name=' '<workflow name=' '<existing path='

P="$(new_proj setupex epsilon)"
printf 'stem: epsilon\ndomain: nonexistent\n' > "$P/session.yml"
mkdomain "$P/.agents/domains" python-style "PROJECT-EXISTING"
run "$P" "$RC" --activity setup --kind domain --name python-style
assert_ok_contains "setup surfaces the project-level existing file" \
    'level="project"' 'PROJECT-EXISTING'
run "$P" "$RC" --activity setup --kind domain --name python-style
assert_not_contains "setup ignores consumption selectors" "domain 'nonexistent' not found"

mkdomain "$FAKE_HOME/.agents/domains" python-style "HOME-EXISTING"
run "$P" "$RC" --activity setup --kind domain --name python-style
assert_ok_contains "shadowed global copy surfaced and flagged" \
    'level="home" shadowed="true"' 'HOME-EXISTING' 'PROJECT-EXISTING'
run "$P" "$RC" --activity setup --kind workflow --name python-style
assert_ok_contains "workflow kind resolves its own template and cascade dir" \
    '<template kind="workflow">'
rm -f "$FAKE_HOME/.agents/domains/python-style.md"

echo "read-section.sh"
PLAN="$TMP/plan.md"
cat > "$PLAN" <<'EOF'
---
status: active
---

## TASKS

### T1 - First task
Why the first task exists.
- [x] Depends on: none
- [x] a step

### T2 - Second task
Why the second task exists.
- [ ] Depends on: T1
- [ ] another step
EOF

run "$TMP" "$RS" "$PLAN" T1
assert_ok_contains "T# slice includes its block" '### T1 - First task' 'Depends on: none'
run "$TMP" "$RS" "$PLAN" T1
assert_not_contains "T# slice stops before next heading" '### T2'
run "$TMP" "$RS" "$PLAN" T2
assert_ok_contains "T# slice reaches EOF" '### T2 - Second task' 'another step'
run "$TMP" "$RS" "$PLAN" T9
assert_fails_with "missing T# id" "heading '### T9 - ...' not found"

NB="$TMP/notebook.md"
cat > "$NB" <<'EOF'
## OPEN QUESTIONS

- [x] Q1: Which config format?
    - RESOLUTION: YAML, per the platform default.
- [ ] Q2: What is the rollout window?
EOF

run "$TMP" "$RS" "$NB" Q1
assert_ok_contains "Q# slice includes nested resolution" 'Q1: Which config format?' 'RESOLUTION: YAML'
run "$TMP" "$RS" "$NB" Q1
assert_not_contains "Q# slice stops at next item" 'Q2'
run "$TMP" "$RS" "$NB" Q7
assert_fails_with "missing Q# id" "list item 'Q7' not found"
run "$TMP" "$RS" "$NB" X1
assert_fails_with "unknown id prefix" "no recognized prefix"
run "$TMP" "$RS" "$TMP/absent.md" T1
assert_fails_with "missing file" "file not found"

echo
echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]
