#!/usr/bin/env bash
set -euo pipefail

# read-section.sh
#
# Slice one precise block out of a live stem markdown file, so a caller gets
# exact content instead of a path to partial-read. Two modes, keyed on the
# id's leading letter:
#
#   T#  heading-block-by-number — the `### T# - {title}` heading, through
#       every line beneath it up to (not including) the next `### ` heading
#       or EOF. Use against plan.md task entries and execute.md log entries.
#   Q#  list-item-by-id — the compact `- [ ] Q# - {title}` — the same shape
#       applies with `- [x] Q#: …` — plus any indented lines beneath it
#       (wrapped text, nested resolution bullets) up to the next top-level
#       `- ` list item or EOF. Use against notebook.md open questions.
#
# Usage: read-section.sh <file> <id>
# Exits nonzero with a stderr message when the id is absent from the file.

usage() {
    echo "usage: read-section.sh <file> <id>" >&2
    exit 1
}

[[ $# -eq 2 ]] || usage

FILE="$1"
ID="$2"

if [[ ! -f "$FILE" ]]; then
    echo "read-section: file not found: '$FILE'" >&2
    exit 1
fi

case "$ID" in
    T[0-9]*) MODE="heading" ;;
    Q[0-9]*) MODE="list-item" ;;
    *)
        echo "read-section: id '$ID' has no recognized prefix (expected 'T#' or 'Q#')" >&2
        exit 1
        ;;
esac

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

case "$MODE" in
    heading)
        if ! slice_heading "$FILE" "$ID"; then
            echo "read-section: heading '### $ID - ...' not found in '$FILE'" >&2
            exit 1
        fi
        ;;
    list-item)
        if ! slice_list_item "$FILE" "$ID"; then
            echo "read-section: list item '$ID' not found in '$FILE'" >&2
            exit 1
        fi
        ;;
esac
