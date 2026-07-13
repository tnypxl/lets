# slice.sh
#
# Shared awk-slicing primitives sourced by resolve-context.sh and
# read-section.sh. Both scripts hand a caller exact content instead of a
# path to partial-read; this lib is the slicing logic they have in common.
# Sourced fragment, not an executable — no shebang, no `set -euo pipefail`
# of its own; that belongs to the entry scripts.

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

# ---------------------------------------------------------------------------
# Mode: heading-block-by-number — slice `### T# - {title}` through the next
# `### ` heading (or EOF).
# ---------------------------------------------------------------------------
slice_heading() {
    local file="$1"
    local id="$2"
    awk -v id="$id" '
        BEGIN { pat = "^### " id " - "; found = 0 }
        $0 ~ pat { found = 1; print; next }
        found && /^### / { exit }
        found { print }
        END { exit (found ? 0 : 1) }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Mode: list-item-by-id — slice the `- [ ] Q# - …`/`- [x] Q#: …` line through
# any indented continuation lines beneath it, up to the next top-level `- `
# list item (or EOF).
# ---------------------------------------------------------------------------
slice_list_item() {
    local file="$1"
    local id="$2"
    awk -v id="$id" '
        BEGIN { pat = "^- \\[[ xX]\\] " id "[:-] "; found = 0 }
        $0 ~ pat { found = 1; print; next }
        found && /^- / { exit }
        found { print }
        END { exit (found ? 0 : 1) }
    ' "$file"
}
