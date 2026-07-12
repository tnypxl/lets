#!/usr/bin/env bash
set -euo pipefail

# resolve-context.sh
#
# The router. Given a caller's flags, assembles the exact markdown context
# that caller needs and prints it to stdout — never a path, never a
# KEY=value line to be parsed and re-fetched. This is what keeps a
# reference-of-references from being partial-read: the script walks every
# hop itself.
#
# Flags:
#   --activity {discuss|research|plan|execute}   required
#   --role     {dispatcher|worker}                default: dispatcher
#   --mode     {full|inline}                      optional (research only, today)
#   --setup    {domain|workflow}                  optional; absent = no overlay
#
# Assembly order:
#   CORE.md  ->  role-sliced verbs/{activity}.md  ->  active-mode marker
#             ->  SETUP.md overlay (preamble + {activity} section), if --setup
#             ->  resolved domain/workflow file bodies, unless --setup
#
# Exits nonzero with a message to stderr on any flag, resolution, or
# coupling failure.

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
ACTIVITY=""
ROLE="dispatcher"
MODE=""
SETUP=""

usage() {
    echo "usage: resolve-context.sh --activity {discuss|research|plan|execute} [--role {dispatcher|worker}] [--mode {full|inline}] [--setup {domain|workflow}]" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --activity) ACTIVITY="${2:-}"; shift 2 ;;
        --role)     ROLE="${2:-}"; shift 2 ;;
        --mode)     MODE="${2:-}"; shift 2 ;;
        --setup)    SETUP="${2:-}"; shift 2 ;;
        *)
            echo "resolve-context: unrecognized argument '$1'" >&2
            usage
            ;;
    esac
done

case "$ACTIVITY" in
    discuss|research|plan|execute) ;;
    "")
        echo "resolve-context: --activity is required" >&2
        usage
        ;;
    *)
        echo "resolve-context: --activity must be one of discuss|research|plan|execute, got '$ACTIVITY'" >&2
        exit 1
        ;;
esac

case "$ROLE" in
    dispatcher|worker) ;;
    *)
        echo "resolve-context: --role must be one of dispatcher|worker, got '$ROLE'" >&2
        exit 1
        ;;
esac

case "$MODE" in
    ""|full|inline) ;;
    *)
        echo "resolve-context: --mode must be one of full|inline, got '$MODE'" >&2
        exit 1
        ;;
esac

case "$SETUP" in
    ""|domain|workflow) ;;
    *)
        echo "resolve-context: --setup must be one of domain|workflow, got '$SETUP'" >&2
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Skill location — resolved from the script's own path, never from $PWD.
# $PWD is the project root (a different tree entirely); the sibling content
# files live beside this script regardless of where the caller stands.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CORE_FILE="$SKILL_DIR/reference/CORE.md"
VERB_FILE="$SKILL_DIR/verbs/${ACTIVITY}.md"
SETUP_FILE="$SKILL_DIR/SETUP.md"

for f in "$CORE_FILE" "$VERB_FILE"; do
    if [[ ! -f "$f" ]]; then
        echo "resolve-context: expected content file missing: '$f'" >&2
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Frontmatter parser — reads the block between the first pair of --- lines.
# Skips comment lines. Returns empty string if key is absent or value empty.
# Use for: notebook.md, domain files, workflow files.
# ---------------------------------------------------------------------------
parse_frontmatter() {
    local file="$1"
    local key="$2"
    awk -v key="$key" '
        BEGIN { in_fm = 0; found_open = 0 }
        /^---[[:space:]]*$/ {
            if (!found_open) { found_open = 1; in_fm = 1; next }
            else             { exit }
        }
        !in_fm { next }
        /^[[:space:]]*#/ { next }
        {
            pat = "^[[:space:]]*" key "[[:space:]]*:[[:space:]]*"
            if (match($0, pat)) {
                val = substr($0, RSTART + RLENGTH)
                sub(/[[:space:]]*#.*$/, "", val)
                sub(/[[:space:]]*$/, "", val)
                print val
                exit
            }
        }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Plain-YAML key parser — reads the whole file without frontmatter delimiters.
# Use for: session.yml (which carries bare YAML, no --- wrapping).
# ---------------------------------------------------------------------------
parse_yaml_key() {
    local file="$1"
    local key="$2"
    awk -v key="$key" '
        /^[[:space:]]*#/ { next }
        {
            pat = "^[[:space:]]*" key "[[:space:]]*:[[:space:]]*"
            if (match($0, pat)) {
                val = substr($0, RSTART + RLENGTH)
                sub(/[[:space:]]*#.*$/, "", val)
                sub(/[[:space:]]*$/, "", val)
                print val
                exit
            }
        }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Cascade resolver — returns absolute path of first hit, or exits nonzero.
# Prints nothing (not empty string) when name is empty — caller checks $name.
# ---------------------------------------------------------------------------
resolve_cascade() {
    local kind="$1"   # "domains" or "workflows"
    local name="$2"
    local root="$3"

    local project_file="$root/.agents/${kind}/${name}.md"
    local home_file="$HOME/.agents/${kind}/${name}.md"

    if [[ -f "$project_file" ]]; then
        echo "$project_file"
    elif [[ -f "$home_file" ]]; then
        echo "$home_file"
    else
        echo "resolve-context: ${kind%s} '${name}' not found in cascade" >&2
        printf "  checked: %s\n" "$project_file" "$home_file" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Project root — walk up from $PWD looking for session.yml.
# ---------------------------------------------------------------------------
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/session.yml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "resolve-context: no session.yml found at or above '$PWD'" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Role slicer — keeps unwrapped content and wrapped content matching $ROLE;
# drops wrapped content belonging to the other role. Strips the fence
# markers themselves either way.
# ---------------------------------------------------------------------------
slice_role() {
    local file="$1"
    local role="$2"
    awk -v role="$role" '
        /^<!-- role:dispatcher -->[[:space:]]*$/ { skip = (role != "dispatcher"); next }
        /^<!-- role:worker -->[[:space:]]*$/     { skip = (role != "worker"); next }
        /^<!-- \/role -->[[:space:]]*$/          { skip = 0; next }
        { if (!skip) print }
    ' "$file"
}

# ---------------------------------------------------------------------------
# SETUP.md slicers — the preamble (everything before the first per-verb
# `## {verb}` heading) and one per-verb `## {activity}` section (through the
# next `## ` heading or EOF).
# ---------------------------------------------------------------------------
slice_setup_preamble() {
    local file="$1"
    awk '
        /^## (discuss|research|plan|execute)[[:space:]]*$/ { exit }
        { print }
    ' "$file"
}

slice_setup_section() {
    local file="$1"
    local activity="$2"
    awk -v activity="$activity" '
        BEGIN { pat = "^## " activity "[[:space:]]*$"; found = 0 }
        $0 ~ pat { found = 1; print; next }
        found && /^## / { exit }
        found { print }
        END { exit (found ? 0 : 1) }
    ' "$file"
}

# ===========================================================================
# Main
# ===========================================================================

ROOT="$(find_project_root)"
SESSION="$ROOT/session.yml"

# Read active stem
STEM="$(parse_yaml_key "$SESSION" "stem")"
if [[ -z "$STEM" ]]; then
    echo "resolve-context: 'stem:' is missing or empty in $SESSION" >&2
    exit 1
fi

# Locate the stem folder — first match of <digits>.<stem>/
STEM_DIR=""
for d in "$ROOT"/[0-9]*."$STEM"/; do
    if [[ -d "$d" ]]; then
        STEM_DIR="${d%/}"
        break
    fi
done

if [[ -z "$STEM_DIR" ]]; then
    echo "resolve-context: no stem folder matching '*.$STEM' found under '$ROOT'" >&2
    exit 1
fi

NOTEBOOK="$STEM_DIR/notebook.md"
if [[ ! -f "$NOTEBOOK" ]]; then
    echo "resolve-context: notebook.md not found at '$NOTEBOOK'" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Domain/workflow resolution — skipped entirely in setup mode. Authoring a
# reference ignores the consumption selectors (`domain:`/`workflow:`); a
# setup stem is building a reference, not reading against one.
# ---------------------------------------------------------------------------
DOMAIN_NAME=""
DOMAIN_FILE=""
WF_NAME=""
WF_FILE=""

if [[ -z "$SETUP" ]]; then
    NB_DOMAIN="$(parse_frontmatter "$NOTEBOOK" "domain")"
    NB_WORKFLOW="$(parse_frontmatter "$NOTEBOOK" "workflow")"
    SESS_DOMAIN="$(parse_yaml_key "$SESSION" "domain")"
    SESS_WORKFLOW="$(parse_yaml_key "$SESSION" "workflow")"

    # Resolve workflow first — its preset may supply the domain.
    WF_NAME="${NB_WORKFLOW:-${SESS_WORKFLOW:-}}"
    if [[ -n "$WF_NAME" ]]; then
        WF_FILE="$(resolve_cascade "workflows" "$WF_NAME" "$ROOT")"
    fi

    # Domain — three-tier precedence: notebook > workflow-preset > session.
    if [[ -n "$NB_DOMAIN" ]]; then
        DOMAIN_NAME="$NB_DOMAIN"
    elif [[ -n "$WF_FILE" ]]; then
        WF_PRESET_DOMAIN="$(parse_frontmatter "$WF_FILE" "domain")"
        DOMAIN_NAME="${WF_PRESET_DOMAIN:-${SESS_DOMAIN:-}}"
    else
        DOMAIN_NAME="${SESS_DOMAIN:-}"
    fi

    if [[ -n "$DOMAIN_NAME" ]]; then
        DOMAIN_FILE="$(resolve_cascade "domains" "$DOMAIN_NAME" "$ROOT")"
    fi

    # Coupling: domain requires_workflow.
    if [[ -n "$DOMAIN_FILE" ]]; then
        REQ_WF="$(parse_frontmatter "$DOMAIN_FILE" "requires_workflow")"
        if [[ -n "$REQ_WF" ]]; then
            if [[ -z "$WF_NAME" || "$WF_NAME" != "$REQ_WF" ]]; then
                echo "resolve-context: domain '$DOMAIN_NAME' requires workflow '$REQ_WF', but no matching workflow is selected" >&2
                exit 1
            fi
        fi
    fi

    # Coupling: workflow requires_domain.
    if [[ -n "$WF_FILE" ]]; then
        REQ_DOM="$(parse_frontmatter "$WF_FILE" "requires_domain")"
        if [[ -n "$REQ_DOM" ]]; then
            if [[ -z "$DOMAIN_NAME" || "$DOMAIN_NAME" != "$REQ_DOM" ]]; then
                echo "resolve-context: workflow '$WF_NAME' requires domain '$REQ_DOM', but no matching domain is selected" >&2
                exit 1
            fi
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Assembly — emit content, not paths or KEY=value lines.
# ---------------------------------------------------------------------------

cat "$CORE_FILE"
echo
slice_role "$VERB_FILE" "$ROLE"

if [[ -n "$MODE" ]]; then
    echo
    echo "ACTIVE MODE: $MODE"
fi

if [[ -n "$SETUP" ]]; then
    echo
    slice_setup_preamble "$SETUP_FILE"
    if ! slice_setup_section "$SETUP_FILE" "$ACTIVITY"; then
        echo "resolve-context: SETUP.md has no '## $ACTIVITY' section" >&2
        exit 1
    fi
fi

if [[ -n "$DOMAIN_FILE" ]]; then
    echo
    cat "$DOMAIN_FILE"
fi

if [[ -n "$WF_FILE" ]]; then
    echo
    cat "$WF_FILE"
fi
