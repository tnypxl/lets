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

run "$EMPTY" "$RC" --activity plan --setup verb
assert_fails_with "bad --setup" "--setup must be one of domain|workflow"

run "$EMPTY" "$RC" --activity plan --bogus x
assert_fails_with "unrecognized argument" "unrecognized argument '--bogus'"

echo "resolve-context.sh — session/stem resolution"
run "$EMPTY" "$RC" --activity discuss
assert_fails_with "no session.yml" "no session.yml found"

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

echo "resolve-context.sh — setup mode"
P="$(new_proj setup epsilon)"
printf 'stem: epsilon\ndomain: nonexistent\n' > "$P/session.yml"
run "$P" "$RC" --activity plan --setup domain
assert_ok_contains "setup mode emits setup segment" 'setup="domain"' '<setup kind="domain">'
run "$P" "$RC" --activity plan --setup domain
assert_not_contains "setup mode skips domain/workflow resolution" '<domain' '<workflow'

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
