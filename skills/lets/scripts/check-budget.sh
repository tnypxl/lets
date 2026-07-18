#!/usr/bin/env bash
set -euo pipefail

# check-budget.sh
#
# The 40-instruction budget gate. An instruction is one prose sentence,
# one list item (more if the item holds several sentences), or one table
# row. Exempt: headings, YAML frontmatter, fenced code blocks, HTML
# comments, blank lines, table separator rows, bare XML tag lines.
#
# Modes:
#   --files   count every instruction doc against its per-file target;
#             fail if any file exceeds 40, warn above its target.
#   --turns   assemble every real turn combination via resolve-context.sh
#             against a throwaway fixture and count what the model would
#             see (router output + SKILL body or agent-def body);
#             fail if any combination exceeds 40, warn at 38+.
#
# Run with no flags to get both.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$(cd "$SKILL_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib/slice.sh"

HARD_CAP=40
TURN_WARN=38

# ---------------------------------------------------------------------------
# Counter — reads markdown on stdin, prints one integer.
# ---------------------------------------------------------------------------
count_stream() {
    awk '
        BEGIN { count = 0; in_fm = 0; in_fence = 0; in_comment = 0 }
        NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
        in_fm { if (/^---[[:space:]]*$/) in_fm = 0; next }
        /^[[:space:]]*```/ { in_fence = !in_fence; next }
        in_fence { next }
        in_comment { if (/-->/) in_comment = 0; next }
        /^[[:space:]]*<!--/ { if ($0 !~ /-->/) in_comment = 1; next }
        /^#/ { next }
        /^[[:space:]]*$/ { next }
        /^\|[-: |]+\|[[:space:]]*$/ { next }
        /^<\/?[a-zA-Z_][^>]*>[[:space:]]*$/ { next }
        /^<!--toc/ { next }
        {
            raw = $0
            line = $0
            is_item = (line ~ /^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]/)
            sub(/^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]+\[[ xX]\][[:space:]]*/, "", line)
            sub(/^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]+/, "", line)
            sub(/^>[[:space:]]*/, "", line)
            gsub(/`[^`]*`/, "code", line)
            gsub(/e\.g\./, "eg", line)
            gsub(/i\.e\./, "ie", line)
            gsub(/vs\./, "vs", line)
            gsub(/etc\.[)]/, "etc)", line)
            n = 0
            while (match(line, /[.!?][)"'"'"']*([[:space:]]|$)/)) {
                n++
                line = substr(line, RSTART + RLENGTH)
            }
            if (raw ~ /^\|/)          count += 1
            else if (is_item)         count += (n > 1 ? n : 1)
            else                      count += n
        }
        END { print count }
    '
}

count_file() { count_stream < "$1"; }

# Body count for a frontmattered doc whose frontmatter is exempt
# (count_stream already skips a leading --- block).

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
FAILED=0

report_row() {
    # $1 label  $2 count  $3 soft-target (empty = none)
    local label="$1" count="$2" target="${3:-}"
    local mark="ok"
    if (( count > HARD_CAP )); then
        mark="FAIL (> $HARD_CAP)"
        FAILED=1
    elif [[ -n "$target" ]] && (( count > target )); then
        mark="warn (> target $target)"
    elif [[ -z "$target" ]] && (( count >= TURN_WARN )); then
        mark="warn (>= $TURN_WARN)"
    fi
    printf "  %-58s %3d  %s\n" "$label" "$count" "$mark"
}

# ---------------------------------------------------------------------------
# --files: per-file counts vs. targets
# ---------------------------------------------------------------------------
check_files() {
    echo "Per-file counts (hard cap $HARD_CAP):"

    # path|target pairs, paths relative to repo root
    local specs=(
        "skills/lets/SKILL.md|11"
        "skills/lets/reference/CORE.md|12"
        "skills/lets/SETUP.md|18"
        "skills/lets/verbs/discuss.md|5"
        "skills/lets/verbs/research.md|9"
        "skills/lets/verbs/plan.md|7"
        "skills/lets/verbs/execute.md|8"
        "planner.md|10"
        "executor.md|8"
        "researcher.md|5"
        "domains/coding.md|14"
        "domains/research.md|14"
        "domains/golang.md|14"
        "workflows/golang.md|10"
        "skills/lets/templates/notebook.md|0"
        "skills/lets/templates/research.md|0"
        "skills/lets/templates/plan.md|0"
        "skills/lets/templates/execute.md|0"
        "skills/lets/templates/domain.md|0"
        "skills/lets/templates/workflow.md|0"
    )

    local spec path target count
    for spec in "${specs[@]}"; do
        path="${spec%%|*}"
        target="${spec##*|}"
        if [[ ! -f "$REPO_DIR/$path" ]]; then
            printf "  %-58s  --  MISSING\n" "$path"
            FAILED=1
            continue
        fi
        count="$(count_file "$REPO_DIR/$path")"
        report_row "$path" "$count" "$target"
    done

    # Verb role slices — each must fit its 5-sentence turn allocation.
    echo "Verb role slices (target 5 each):"
    local verb role
    for verb in discuss research plan execute; do
        for role in dispatcher worker; do
            count="$(slice_role "$REPO_DIR/skills/lets/verbs/$verb.md" "$role" | count_stream)"
            report_row "verbs/$verb.md --role $role" "$count" 5
        done
    done
}

# ---------------------------------------------------------------------------
# --turns: assembled-turn counts via the real router against a fixture
# ---------------------------------------------------------------------------
check_turns() {
    echo "Assembled turns (hard cap $HARD_CAP, warn >= $TURN_WARN):"

    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/lets-budget.XXXXXX")"
    trap 'rm -rf "$tmp"' RETURN

    local proj="$tmp/proj" home="$tmp/home"
    mkdir -p "$proj/.agents/domains" "$proj/.agents/workflows" "$proj/1.fixture" "$home"

    local f
    for f in "$REPO_DIR"/domains/*.md; do
        [[ "$(basename "$f")" == "README.md" ]] && continue
        cp "$f" "$proj/.agents/domains/"
    done
    for f in "$REPO_DIR"/workflows/*.md; do
        [[ "$(basename "$f")" == "README.md" ]] && continue
        cp "$f" "$proj/.agents/workflows/"
    done

    echo "stem: fixture" > "$proj/session.yml"

    local skill_count planner_count executor_count researcher_count
    skill_count="$(count_file "$REPO_DIR/skills/lets/SKILL.md")"
    planner_count="$(count_file "$REPO_DIR/planner.md")"
    executor_count="$(count_file "$REPO_DIR/executor.md")"
    researcher_count="$(count_file "$REPO_DIR/researcher.md")"

    write_notebook() {
        # $1 = extra frontmatter lines (may be empty)
        # $2 = deliverable form for the APPROACH line (may be empty)
        {
            echo "---"
            echo "title: fixture"
            echo "status: active"
            [[ -n "$1" ]] && printf '%s\n' "$1"
            echo "---"
            echo
            echo "## OBJECTIVE"
            echo
            echo "## APPROACH"
            if [[ -n "${2:-}" ]]; then
                echo
                echo "Deliverable: $2 — fixture."
            fi
        } > "$proj/1.fixture/notebook.md"
    }

    run_turn() {
        # $1 label  $2 extra-body-count  $3.. router args
        local label="$1" extra="$2"; shift 2
        local out count
        if ! out="$(cd "$proj" && HOME="$home" "$SCRIPT_DIR/resolve-context.sh" "$@" 2>&1)"; then
            printf "  %-58s  --  ROUTER FAILED: %s\n" "$label" "$out"
            FAILED=1
            return
        fi
        count="$(( $(printf '%s\n' "$out" | count_stream) + extra ))"
        report_row "$label" "$count" ""
    }

    # selector case name → notebook frontmatter → deliverable form
    local cases=(
        "none||"
        "coding|domain: coding|change"
        "research-dom|domain: research|report"
        "golang-dom|domain: golang|tool"
        "golang-wf|workflow: golang|tool"
    )

    local case_spec case_name case_fm case_form verb
    for case_spec in "${cases[@]}"; do
        case_name="${case_spec%%|*}"
        case_form="${case_spec##*|}"
        case_fm="${case_spec#*|}"; case_fm="${case_fm%|*}"
        write_notebook "$case_fm" "$case_form"

        for verb in discuss research plan execute; do
            run_turn "dispatcher $verb [$case_name]" "$skill_count" \
                --activity "$verb" --role dispatcher
        done

        run_turn "worker research/full [$case_name]" "$researcher_count" \
            --activity research --role worker --mode full
        run_turn "worker research/inline [$case_name]" "$researcher_count" \
            --activity research --role worker --mode inline
        run_turn "worker plan [$case_name]" "$planner_count" \
            --activity plan --role worker
        run_turn "worker execute [$case_name]" "$executor_count" \
            --activity execute --role worker
    done

    # Setup turns — the guided flow, one per kind.
    local kind
    for kind in domain workflow; do
        run_turn "setup [$kind]" "$skill_count" \
            --activity setup --kind "$kind" --name fixture
    done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
DO_FILES=0
DO_TURNS=0

if [[ $# -eq 0 ]]; then
    DO_FILES=1
    DO_TURNS=1
fi
while [[ $# -gt 0 ]]; do
    case "$1" in
        --files) DO_FILES=1; shift ;;
        --turns) DO_TURNS=1; shift ;;
        *)
            echo "usage: check-budget.sh [--files] [--turns]" >&2
            exit 1
            ;;
    esac
done

(( DO_FILES )) && check_files
(( DO_TURNS )) && check_turns

if (( FAILED )); then
    echo "BUDGET EXCEEDED"
    exit 1
fi
echo "All within budget."
