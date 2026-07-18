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
# Section slicer — one `## {heading}` section (through the next `## `
# heading or EOF).
# ---------------------------------------------------------------------------
slice_section() {
    local file="$1"
    local heading="$2"
    awk -v heading="$heading" '
        BEGIN { pat = "^## " heading "[[:space:]]*$"; found = 0 }
        $0 ~ pat { found = 1; print; next }
        found && /^## / { exit }
        found { print }
        END { exit (found ? 0 : 1) }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Reference-file slicers — the typed sections a domain/workflow file may
# carry (`## deliverables`, `## directives`, `## template:{artifact}`).
# All are comment-aware: heading-looking lines inside <!-- --> blocks
# (e.g. a task-shape example) never open or close a section.
# ---------------------------------------------------------------------------

# Directive lines for one activity — the `- {activity}: {rule}` and
# `- all: {rule}` items of `## directives`, selector prefix stripped.
slice_directives() {
    local file="$1"
    local activity="$2"
    awk -v act="$activity" '
        incm { if (/-->/) incm = 0; next }
        /^[[:space:]]*<!--/ && $0 !~ /-->/ { incm = 1; next }
        /^## directives[[:space:]]*$/ { insec = 1; next }
        insec && /^## / { insec = 0 }
        insec {
            pat = "^-[[:space:]]+(" act "|all):[[:space:]]*"
            if (match($0, pat)) print substr($0, RSTART + RLENGTH)
        }
    ' "$file"
}

# Deliverable form names — first token before `:` of each `## deliverables`
# list item.
deliverable_forms() {
    local file="$1"
    awk '
        incm { if (/-->/) incm = 0; next }
        /^[[:space:]]*<!--/ && $0 !~ /-->/ { incm = 1; next }
        /^## deliverables[[:space:]]*$/ { insec = 1; next }
        insec && /^## / { insec = 0 }
        insec && /^-[[:space:]]+[A-Za-z0-9_-]+:/ {
            line = $0
            sub(/^-[[:space:]]+/, "", line)
            sub(/:.*/, "", line)
            print line
        }
    ' "$file"
}

# Body minus the harness-only sections — everything except `## directives`
# and every `## template:*` section. What a <domain>/<workflow> segment emits.
strip_meta_sections() {
    local file="${1:-}"
    awk '
        incm { if (/-->/) incm = 0; if (!skip) print; next }
        /^[[:space:]]*<!--/ && $0 !~ /-->/ { incm = 1; if (!skip) print; next }
        /^## directives[[:space:]]*$/ || /^## template:/ { skip = 1; next }
        skip && /^## / { skip = 0 }
        !skip { print }
    ' "${file:-/dev/stdin}"
}

# Workflow body for one activity — the file minus harness-only sections and
# minus the per-verb sections of every OTHER verb, so plan guidance never
# spends a discuss turn's budget.
slice_workflow_body() {
    local file="$1"
    local activity="$2"
    awk -v act="$activity" '
        incm { if (/-->/) incm = 0; if (!skip) print; next }
        /^[[:space:]]*<!--/ && $0 !~ /-->/ { incm = 1; if (!skip) print; next }
        /^## directives[[:space:]]*$/ || /^## template:/ { skip = 1; next }
        /^## (discuss|research|plan|execute)[[:space:]]*$/ {
            hd = $0; sub(/^## /, "", hd); sub(/[[:space:]]+$/, "", hd)
            skip = (hd != act)
            if (!skip) print
            next
        }
        /^## / { skip = 0; print; next }
        !skip { print }
    ' "$file"
}

# The `### {SECTION}` override blocks inside `## template:{artifact}`.
slice_template_overrides() {
    local file="$1"
    local artifact="$2"
    awk -v art="$artifact" '
        BEGIN { pat = "^## template:" art "[[:space:]]*$" }
        incm { if (/-->/) incm = 0; if (insec) print; next }
        /^[[:space:]]*<!--/ && $0 !~ /-->/ { incm = 1; if (insec) print; next }
        $0 ~ pat { insec = 1; next }
        insec && /^## / { exit }
        insec { print }
    ' "$file"
}

# Merge one overrides blob (a stream of `### {SECTION}` blocks) into a base
# template. A block whose heading text matches a base `## `/`### ` heading
# replaces that section body (base heading line and level kept, skip runs to
# the next heading of the same or higher level); an unmatched block is
# appended at the end as a new `## {SECTION}`. Apply repeatedly for layered
# overrides — the later application wins.
merge_template() {
    local base="$1"
    local overrides="$2"
    awk '
        FNR == NR {
            if (oc) { if (/-->/) oc = 0; if (cur != "") body[cur] = body[cur] $0 "\n"; next }
            if (/^[[:space:]]*<!--/ && $0 !~ /-->/) { oc = 1; if (cur != "") body[cur] = body[cur] $0 "\n"; next }
            if (/^### /) {
                cur = substr($0, 5)
                sub(/[[:space:]]+$/, "", cur)
                if (!(cur in body)) order[++n] = cur
                body[cur] = ""
                next
            }
            if (cur != "") body[cur] = body[cur] $0 "\n"
            next
        }
        {
            if (bc) { if (/-->/) bc = 0; if (!skip) print; next }
            if (/^[[:space:]]*<!--/ && $0 !~ /-->/) { bc = 1; if (!skip) print; next }
            if (/^##/) {
                match($0, /^#+/); lvl = RLENGTH
                text = $0
                sub(/^#+[[:space:]]*/, "", text)
                sub(/[[:space:]]+$/, "", text)
                if (skip && lvl <= skiplvl) skip = 0
                if (!skip) {
                    if (text in body) {
                        print
                        printf "%s", body[text]
                        used[text] = 1
                        skip = 1; skiplvl = lvl
                    } else print
                }
                next
            }
            if (!skip) print
        }
        END {
            for (i = 1; i <= n; i++) {
                t = order[i]
                if (!(t in used)) printf "\n## %s\n%s", t, body[t]
            }
        }
    ' "$overrides" "$base"
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
