#!/usr/bin/env bash
set -euo pipefail

# resolve-context.sh
#
# The router. Given a caller's flags, assembles the exact context that
# caller needs and prints it to stdout as one rooted, tagged
# <lets_context> document — never a path, never a KEY=value line to be
# parsed and re-fetched. This is what keeps a reference-of-references from
# being partial-read: the script walks every hop itself.
#
# Flags:
#   --activity {discuss|research|plan|execute|setup}   required
#   --role     {dispatcher|worker}                default: dispatcher
#   --mode     {full|inline}                      optional (research only, today)
#   --kind     {domain|workflow}                  required with --activity setup
#   --name     {reference-name}                   required with --activity setup
#   --template                                    print the activity's artifact
#                                                 template with any domain/
#                                                 workflow overrides merged,
#                                                 instead of a context document
#
# Assembly order (children of the <lets_context> root):
#   <core>  ->  <verb name>  (role-sliced)
#           ->  <domain name> then <workflow name> (running verb's slice)
#           ->  <directives> (matching typed rules, emitted last)
# For --activity setup the children are instead:
#   <core>  ->  <setup kind name>  ->  <template kind>
#           ->  <existing path level [shadowed]> per same-name cascade hit
# Root attributes carry the run parameters; per-segment frontmatter is
# stripped on emit, and a reference's harness-only sections (## directives,
# ## template:*) never appear inside its segment.
#
# Exits nonzero with a message to stderr on any flag, resolution, or
# coupling failure.

# ---------------------------------------------------------------------------
# Skill location — resolved from the script's own path, never from $PWD.
# $PWD is the project root (a different tree entirely); the sibling content
# files live beside this script regardless of where the caller stands.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/slice.sh"

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
ACTIVITY=""
ROLE="dispatcher"
MODE=""
KIND=""
NAME=""
TEMPLATE=0

usage() {
    echo "usage: resolve-context.sh --activity {discuss|research|plan|execute|setup} [--role {dispatcher|worker}] [--mode {full|inline}] [--kind {domain|workflow} --name {name}] [--template]" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --activity) ACTIVITY="${2:-}"; shift 2 ;;
        --role)     ROLE="${2:-}"; shift 2 ;;
        --mode)     MODE="${2:-}"; shift 2 ;;
        --kind)     KIND="${2:-}"; shift 2 ;;
        --name)     NAME="${2:-}"; shift 2 ;;
        --template) TEMPLATE=1; shift ;;
        *)
            echo "resolve-context: unrecognized argument '$1'" >&2
            usage
            ;;
    esac
done

case "$ACTIVITY" in
    discuss|research|plan|execute|setup) ;;
    "")
        echo "resolve-context: --activity is required" >&2
        usage
        ;;
    *)
        echo "resolve-context: --activity must be one of discuss|research|plan|execute|setup, got '$ACTIVITY'" >&2
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

if [[ "$ACTIVITY" == "setup" ]]; then
    case "$KIND" in
        domain|workflow) ;;
        "")
            echo "resolve-context: --activity setup requires --kind {domain|workflow}" >&2
            exit 1
            ;;
        *)
            echo "resolve-context: --kind must be one of domain|workflow, got '$KIND'" >&2
            exit 1
            ;;
    esac
    if [[ -z "$NAME" ]]; then
        echo "resolve-context: --activity setup requires --name {reference-name}" >&2
        exit 1
    fi
    if [[ ! "$NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
        echo "resolve-context: --name must be letters, digits, dashes, underscores, got '$NAME'" >&2
        exit 1
    fi
    if (( TEMPLATE )); then
        echo "resolve-context: --template does not apply to --activity setup" >&2
        exit 1
    fi
elif [[ -n "$KIND" || -n "$NAME" ]]; then
    echo "resolve-context: --kind/--name apply only to --activity setup" >&2
    exit 1
fi

CORE_FILE="$SKILL_DIR/reference/CORE.md"
SETUP_FILE="$SKILL_DIR/SETUP.md"

if [[ ! -f "$CORE_FILE" ]]; then
    echo "resolve-context: expected content file missing: '$CORE_FILE'" >&2
    exit 1
fi

VERB_FILE=""
if [[ "$ACTIVITY" != "setup" ]]; then
    VERB_FILE="$SKILL_DIR/verbs/${ACTIVITY}.md"
    if [[ ! -f "$VERB_FILE" ]]; then
        echo "resolve-context: expected content file missing: '$VERB_FILE'" >&2
        exit 1
    fi
fi

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
# Frontmatter stripper — drops a leading `---`...`---` block and prints the
# remaining body verbatim. Files with no leading `---` block (e.g. domain
# files) pass through unchanged. Reads a file path, or stdin when called
# with no argument.
# ---------------------------------------------------------------------------
strip_frontmatter() {
    local file="${1:-}"
    awk '
        NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
        in_fm { if (/^---[[:space:]]*$/) { in_fm = 0 }; next }
        { print }
    ' "${file:-/dev/stdin}"
}

# ===========================================================================
# Main
# ===========================================================================

# ---------------------------------------------------------------------------
# Setup — authoring a reference is stemless: no session.yml required (the
# guided flow works from any directory), no verb slice, no consumption
# selectors. Emit the flow, the kind's authoring template, and any same-name
# file already on the cascade, then stop.
# ---------------------------------------------------------------------------
if [[ "$ACTIVITY" == "setup" ]]; then
    KIND_TEMPLATE="$SKILL_DIR/templates/${KIND}.md"
    for f in "$SETUP_FILE" "$KIND_TEMPLATE"; do
        if [[ ! -f "$f" ]]; then
            echo "resolve-context: expected content file missing: '$f'" >&2
            exit 1
        fi
    done

    ROOT="$(find_project_root 2>/dev/null)" || true
    ROOT="${ROOT:-$PWD}"
    PROJECT_REF="$ROOT/.agents/${KIND}s/${NAME}.md"
    HOME_REF="$HOME/.agents/${KIND}s/${NAME}.md"

    echo "<lets_context activity=\"setup\" kind=\"$KIND\" name=\"$NAME\">"

    echo "<core>"
    strip_frontmatter "$CORE_FILE"
    echo "</core>"
    echo ""

    echo "<setup kind=\"$KIND\" name=\"$NAME\">"
    strip_frontmatter "$SETUP_FILE"
    echo "</setup>"
    echo ""

    echo "<template kind=\"$KIND\">"
    cat "$KIND_TEMPLATE"
    echo "</template>"
    echo ""

    SHADOWED=""
    if [[ -f "$PROJECT_REF" && -f "$HOME_REF" ]]; then
        SHADOWED=1
    fi
    if [[ -f "$PROJECT_REF" ]]; then
        echo "<existing path=\"$PROJECT_REF\" level=\"project\">"
        cat "$PROJECT_REF"
        echo "</existing>"
        echo ""
    fi
    if [[ -f "$HOME_REF" ]]; then
        HOME_ATTRS="path=\"$HOME_REF\" level=\"home\""
        if [[ -n "$SHADOWED" ]]; then
            HOME_ATTRS="$HOME_ATTRS shadowed=\"true\""
        fi
        echo "<existing $HOME_ATTRS>"
        cat "$HOME_REF"
        echo "</existing>"
        echo ""
    fi

    echo "</lets_context>"
    exit 0
fi

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

# In --template mode the artifact being scaffolded may predate the stem
# folder or notebook (discuss scaffolds the notebook itself); selectors then
# fall back to session.yml alone. Every other call hard-requires both.
NOTEBOOK=""
if [[ -z "$STEM_DIR" ]]; then
    if (( ! TEMPLATE )); then
        echo "resolve-context: no stem folder matching '*.$STEM' found under '$ROOT'" >&2
        exit 1
    fi
else
    NOTEBOOK="$STEM_DIR/notebook.md"
    if [[ ! -f "$NOTEBOOK" ]]; then
        if (( ! TEMPLATE )); then
            echo "resolve-context: notebook.md not found at '$NOTEBOOK'" >&2
            exit 1
        fi
        NOTEBOOK=""
    fi
fi

# ---------------------------------------------------------------------------
# Domain/workflow resolution.
# ---------------------------------------------------------------------------
DOMAIN_NAME=""
DOMAIN_FILE=""
WF_NAME=""
WF_FILE=""

NB_DOMAIN=""
NB_WORKFLOW=""
if [[ -n "$NOTEBOOK" ]]; then
    NB_DOMAIN="$(parse_frontmatter "$NOTEBOOK" "domain")"
    NB_WORKFLOW="$(parse_frontmatter "$NOTEBOOK" "workflow")"
fi
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

# ---------------------------------------------------------------------------
# Template mode — print the activity's artifact template with reference
# overrides merged (base -> domain -> workflow; workflow wins) and stop.
# ---------------------------------------------------------------------------
if (( TEMPLATE )); then
    case "$ACTIVITY" in
        discuss) ARTIFACT="notebook" ;;
        *)       ARTIFACT="$ACTIVITY" ;;
    esac
    BASE_TEMPLATE="$SKILL_DIR/templates/${ARTIFACT}.md"
    if [[ ! -f "$BASE_TEMPLATE" ]]; then
        echo "resolve-context: template missing: '$BASE_TEMPLATE'" >&2
        exit 1
    fi

    MERGED="$(mktemp "${TMPDIR:-/tmp}/lets-template.XXXXXX")"
    OVERRIDES="$(mktemp "${TMPDIR:-/tmp}/lets-overrides.XXXXXX")"
    trap 'rm -f "$MERGED" "$OVERRIDES"' EXIT
    cat "$BASE_TEMPLATE" > "$MERGED"

    for ref_file in "$DOMAIN_FILE" "$WF_FILE"; do
        [[ -n "$ref_file" ]] || continue
        slice_template_overrides "$ref_file" "$ARTIFACT" > "$OVERRIDES"
        if [[ -s "$OVERRIDES" ]]; then
            merge_template "$MERGED" "$OVERRIDES" > "$MERGED.next"
            mv "$MERGED.next" "$MERGED"
        fi
    done

    cat "$MERGED"
    exit 0
fi

# ---------------------------------------------------------------------------
# Deliverable gate — a domain that defines deliverable forms blocks planning
# until the notebook APPROACH names one. Discuss gets the generated GATE
# directive (assembly below); plan gets this hard stop.
# ---------------------------------------------------------------------------
DELIVERABLE_FORMS=""
if [[ -n "$DOMAIN_FILE" ]]; then
    DELIVERABLE_FORMS="$(deliverable_forms "$DOMAIN_FILE")"
fi

if [[ -n "$DELIVERABLE_FORMS" && "$ACTIVITY" == "plan" && "$ROLE" == "dispatcher" ]]; then
    FORMS_ALT="$(printf '%s\n' "$DELIVERABLE_FORMS" | paste -sd'|' -)"
    if ! slice_section "$NOTEBOOK" "APPROACH" 2>/dev/null \
            | grep -Eq "Deliverable:[[:space:]]*(${FORMS_ALT})([^A-Za-z0-9_-]|$)"; then
        FORMS_CSV="$(printf '%s\n' "$DELIVERABLE_FORMS" | paste -sd, - | sed 's/,/, /g')"
        echo "resolve-context: domain '$DOMAIN_NAME' defines deliverable forms, but the notebook APPROACH names none" >&2
        echo "  add a 'Deliverable: {form} — {name}' line using one of: $FORMS_CSV — settle it in discuss before planning" >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# Assembly — one rooted, tagged <lets_context> document. Frontmatter is
# stripped from every file/slice segment via strip_frontmatter(); the tag
# and its name attribute carry what the frontmatter used to say.
# ---------------------------------------------------------------------------

ROOT_ATTRS="activity=\"$ACTIVITY\" role=\"$ROLE\""
[[ -n "$MODE" ]]  && ROOT_ATTRS="$ROOT_ATTRS mode=\"$MODE\""

echo "<lets_context $ROOT_ATTRS>"

echo "<core>"
strip_frontmatter "$CORE_FILE"
echo "</core>"
echo ""

echo "<verb name=\"$ACTIVITY\">"
slice_role "$VERB_FILE" "$ROLE" | strip_frontmatter
echo "</verb>"
echo ""

if [[ -n "$DOMAIN_FILE" ]]; then
    echo "<domain name=\"$DOMAIN_NAME\">"
    strip_frontmatter "$DOMAIN_FILE" | strip_meta_sections
    echo "</domain>"
    echo ""
fi

if [[ -n "$WF_FILE" ]]; then
    echo "<workflow name=\"$WF_NAME\">"
    strip_frontmatter "$WF_FILE" | slice_workflow_body /dev/stdin "$ACTIVITY"
    echo "</workflow>"
    echo ""
fi

# Typed directives — emitted last so they land with full weight. Each
# line names its source; a generated GATE holds discuss to naming a
# deliverable when the domain defines forms.
DIRECTIVES=""
if [[ -n "$DOMAIN_FILE" ]]; then
    DIRECTIVES+="$(slice_directives "$DOMAIN_FILE" "$ACTIVITY" | sed "s/^/- [domain:$DOMAIN_NAME] /")"
fi
if [[ -n "$WF_FILE" ]]; then
    WF_DIRECTIVES="$(slice_directives "$WF_FILE" "$ACTIVITY" | sed "s/^/- [workflow:$WF_NAME] /")"
    if [[ -n "$WF_DIRECTIVES" ]]; then
        DIRECTIVES+="${DIRECTIVES:+$'\n'}$WF_DIRECTIVES"
    fi
fi
if [[ -n "$DELIVERABLE_FORMS" && "$ACTIVITY" == "discuss" ]]; then
    FORMS_CSV="$(printf '%s\n' "$DELIVERABLE_FORMS" | paste -sd, - | sed 's/,/, /g')"
    GATE_LINE="- [domain:$DOMAIN_NAME] GATE the APPROACH is not committable until it carries a 'Deliverable: {form} — {name}' line using one of: $FORMS_CSV"
    DIRECTIVES+="${DIRECTIVES:+$'\n'}$GATE_LINE"
fi

if [[ -n "$DIRECTIVES" ]]; then
    echo "<directives binding=\"true\" activity=\"$ACTIVITY\">"
    printf '%s\n' "$DIRECTIVES"
    echo "</directives>"
    echo ""
fi

echo "</lets_context>"
