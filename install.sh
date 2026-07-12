#!/usr/bin/env bash
#
# Symlink this directory's agents and skills into a Claude config dir, and
# expose the domain/workflow cascade floor into ~/.agents.
#
#   install.sh --claude              install (symlink) into ~/.claude and ~/.agents
#   install.sh --claude --uninstall  remove the symlinks this script created
#
# Agents are the *.md files in this directory that begin with YAML frontmatter
# (SYSTEM.md and other plain docs are ignored). Skills are the subdirectories of
# ./skills/ that contain a SKILL.md (so ./skills/scripts/ is ignored).
#
# The domain/workflow cascade floor: ./domains/ and ./workflows/ are linked as
# ~/.agents/domains and ~/.agents/workflows so the skill can resolve named
# domains and workflows against $HOME/.agents/<kind>/<name>.md on any machine.
#
# Override the Claude config root with CLAUDE_HOME (defaults to ~/.claude).
# Override the agents cascade root with AGENTS_HOME (defaults to ~/.agents).
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"

usage() {
  cat <<'EOF'
Symlink this directory's agents and skills into a Claude config dir, and
expose the domain/workflow cascade floor into ~/.agents.

  install.sh --claude              install (symlink) into ~/.claude and ~/.agents
  install.sh --claude --uninstall  remove the symlinks this script created

Agents are the *.md files in this directory that begin with YAML frontmatter
(SYSTEM.md and other plain docs are ignored). Skills are the subdirectories of
./skills/ that contain a SKILL.md (so ./skills/scripts/ is ignored).

The domain/workflow cascade floor: ./domains/ and ./workflows/ are linked as
~/.agents/domains and ~/.agents/workflows so the skill can resolve named
domains and workflows against $HOME/.agents/<kind>/<name>.md on any machine.

Override the Claude config root with CLAUDE_HOME (defaults to ~/.claude).
Override the agents cascade root with AGENTS_HOME (defaults to ~/.agents).
EOF
}

# A symlink is "ours" if its target matches src ignoring a trailing slash
# (pre-existing skill links were created with one; we create them without).
links_to() { [[ "$(readlink "$1")" == "${2%/}" || "$(readlink "$1")" == "${2%/}/" ]]; }

# Print the absolute path of every agent definition (root *.md with frontmatter).
collect_agents() {
  local f
  for f in "$SOURCE_DIR"/*.md; do
    [[ -e "$f" ]] || continue
    [[ "$(head -n1 "$f")" == "---" ]] && printf '%s\n' "$f"
  done
}

# Print the absolute path of every skill (./skills/*/ holding a SKILL.md).
collect_skills() {
  local d
  for d in "$SOURCE_DIR"/skills/*/; do
    [[ -f "${d}SKILL.md" ]] && printf '%s\n' "${d%/}"
  done
}

# Print top-level shared docs in ./skills/ that skills reference as
# ../<doc>.md and so must sit beside them in the skills dir. (Skill-private
# references, like lets/reference/CORE.md, ride along with the skill dir.)
collect_skill_docs() {
  local f
  for f in "$SOURCE_DIR"/skills/*.md; do
    [[ -e "$f" ]] && printf '%s\n' "$f"
  done
}

# Resolve the hash tool once (shasum -a 256, falling back to sha256sum),
# caching the choice so later calls don't re-probe.
HASH_TOOL=()
resolve_hash_tool() {
  [[ ${#HASH_TOOL[@]} -eq 0 ]] || return 0
  if command -v shasum >/dev/null 2>&1; then
    HASH_TOOL=(shasum -a 256)
  elif command -v sha256sum >/dev/null 2>&1; then
    HASH_TOOL=(sha256sum)
  else
    echo "error: need shasum or sha256sum to hash files" >&2
    exit 1
  fi
}

# Print the bare content hash of a file (strips the trailing "  filename"). A
# directory (a skill, installed whole rather than per-file) is hashed as the
# sorted per-file hashes of its contents, combined through the same tool, so
# either a changed file or a changed file set changes the result.
content_hash() {
  resolve_hash_tool
  if [[ -d "$1" ]]; then
    local dir="$1" f
    ( cd "$dir" && find . -type f | sort | while IFS= read -r f; do
        "${HASH_TOOL[@]}" "$f"
      done ) | "${HASH_TOOL[@]}" | awk '{print $1}'
  else
    "${HASH_TOOL[@]}" "$1" | awk '{print $1}'
  fi
}

# Serialize placed (dest, hash) pairs to $AGENTS_HOME/.lets-lock, creating
# AGENTS_HOME if absent. Reads "<hash> <dest>" lines on stdin, one pair per
# line, whitespace-separated, hash first — callers pipe or redirect their
# pairs in. Writes them back out as "<hash>  <dest>" (double space, mirroring
# shasum's own output) so a later `while read hash dest` parses the manifest
# with no extra tools.
write_manifest() {
  mkdir -p "$AGENTS_HOME"
  local manifest="$AGENTS_HOME/.lets-lock" hash dest
  : > "$manifest"
  while read -r hash dest; do
    printf '%s  %s\n' "$hash" "$dest" >> "$manifest"
  done
  echo "  manifest -> ${manifest/#$HOME/\~} ($(wc -l < "$manifest" | tr -d ' ') entries)"
}

# Global manifest lookup, dest -> recorded hash, populated by load_manifest.
declare -A MANIFEST=()

# Populate MANIFEST from $AGENTS_HOME/.lets-lock. Reads back the "<hash>
# <dest>" lines write_manifest wrote (hash first, whitespace-separated,
# extra spaces collapsed by `read`). A missing manifest leaves MANIFEST
# empty rather than erroring — the first-install case.
load_manifest() {
  MANIFEST=()
  local manifest="$AGENTS_HOME/.lets-lock" hash dest
  [[ -f "$manifest" ]] || return 0
  while read -r hash dest; do
    MANIFEST["$dest"]="$hash"
  done < "$manifest"
}

# Classify dest against the loaded MANIFEST: echoes one of "absent",
# "matches-recorded", or "diverged". A dest with no manifest entry (foreign
# file, or a lost manifest) is diverged, not absent — absent means nothing is
# there yet. `-v MANIFEST[$dest]` tests key presence without tripping `-u` on
# an unset lookup.
classify_dest() {
  local dest="$1"
  [[ -e "$dest" ]] || { echo "absent"; return; }
  [[ -v MANIFEST[$dest] ]] || { echo "diverged"; return; }
  [[ "$(content_hash "$dest")" == "${MANIFEST[$dest]}" ]] && echo "matches-recorded" || echo "diverged"
}

link_one() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    links_to "$dest" "$src" && { echo "  ok    ${dest/#$HOME/\~} (already linked)"; return; }
    echo "  warn  ${dest/#$HOME/\~} -> $(readlink "$dest") (not ours; skipping)"; return
  fi
  [[ -e "$dest" ]] && { echo "  warn  ${dest/#$HOME/\~} exists, not a symlink (skipping)"; return; }
  ln -s "$src" "$dest"
  echo "  link  ${dest/#$HOME/\~}"
}

unlink_one() {
  local src="$1" dest="$2"
  [[ -L "$dest" ]] || return 0
  if links_to "$dest" "$src"; then
    rm "$dest"; echo "  rm    ${dest/#$HOME/\~}"
  else
    echo "  skip  ${dest/#$HOME/\~} -> $(readlink "$dest") (not ours)"
  fi
}

apply() {
  local fn="$1" src
  echo "Agents -> ${CLAUDE_HOME/#$HOME/\~}/agents/"
  while IFS= read -r src; do "$fn" "$src" "$CLAUDE_HOME/agents/$(basename "$src")"; done < <(collect_agents)
  echo "Skills -> ${CLAUDE_HOME/#$HOME/\~}/skills/"
  while IFS= read -r src; do "$fn" "$src" "$CLAUDE_HOME/skills/$(basename "$src")"; done < <(collect_skills)
  while IFS= read -r src; do "$fn" "$src" "$CLAUDE_HOME/skills/$(basename "$src")"; done < <(collect_skill_docs)
  echo "Cascade floor -> ${AGENTS_HOME/#$HOME/\~}/"
  [[ -d "$SOURCE_DIR/domains"   ]] && "$fn" "$SOURCE_DIR/domains"   "$AGENTS_HOME/domains"
  [[ -d "$SOURCE_DIR/workflows" ]] && "$fn" "$SOURCE_DIR/workflows" "$AGENTS_HOME/workflows"
}

# Print "<src><TAB><dest>" for every installable file, one pair per line
# (TAB-separated so paths with spaces survive intact) — the flat enumeration
# the copy loop and manifest consume. Agents, skills, and skill docs map
# straight through collect_*; skills install as whole directories (a skill
# dest is its directory, not its files), while ./domains and ./workflows are
# walked into individual files so each one gets its own manifest entry,
# mirroring its path under AGENTS_HOME/<domains|workflows>/….
#
# Group headings for the operator go to stderr, not stdout — stdout is a
# pure pair stream, so a caller can consume it with
#   while IFS=$'\t' read -r src dest; do ... done < <(enumerate_pairs)
# without headings landing in $src/$dest. The headings still print to the
# terminal (stderr isn't discarded), same wording as apply()'s today.
enumerate_pairs() {
  local src f rel group dir

  echo "Agents -> ${CLAUDE_HOME/#$HOME/\~}/agents/" >&2
  while IFS= read -r src; do
    printf '%s\t%s\n' "$src" "$CLAUDE_HOME/agents/$(basename "$src")"
  done < <(collect_agents)

  echo "Skills -> ${CLAUDE_HOME/#$HOME/\~}/skills/" >&2
  while IFS= read -r src; do
    printf '%s\t%s\n' "$src" "$CLAUDE_HOME/skills/$(basename "$src")"
  done < <(collect_skills)
  while IFS= read -r src; do
    printf '%s\t%s\n' "$src" "$CLAUDE_HOME/skills/$(basename "$src")"
  done < <(collect_skill_docs)

  echo "Cascade floor -> ${AGENTS_HOME/#$HOME/\~}/" >&2
  for group in domains workflows; do
    dir="$SOURCE_DIR/$group"
    [[ -d "$dir" ]] || continue
    while IFS= read -r f; do
      rel="${f#"$dir"/}"
      printf '%s\t%s\n' "$f" "$AGENTS_HOME/$group/$rel"
    done < <(find "$dir" -type f | sort)
  done
}

# Copy src into dest, creating dest's parent dir. A directory src (a skill,
# installed whole) is replaced wholesale — rm -rf then cp -R — so a file
# removed from src doesn't linger as stale content at dest; a file src is a
# plain overwrite. Shared by install_copy's absent and matches-recorded arms,
# which both place fresh content the same way.
place_pair() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$src" ]]; then
    rm -rf "$dest"
    cp -R "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
}

# Ask once per run whether forced replacement of diverged dests may proceed.
# Memoized in force_confirmed so N diverged dests share one prompt, not one
# each. --yes pre-answers yes without asking. install_copy's loop reads
# enumerate_pairs off stdin, so the prompt can't use fd 0/1 — it opens
# /dev/tty directly; if that open fails (no controlling terminal: piped,
# backgrounded, CI) the answer is no rather than hanging.
force_confirmed=""
confirm_force() {
  if [[ -z "$force_confirmed" ]]; then
    if [[ -n "${assume_yes:-}" ]]; then
      force_confirmed="yes"
    elif { exec 3<>/dev/tty; } 2>/dev/null; then
      local reply=""
      read -r -p "Replace diverged dest(s) with fresh content from source? [y/N] " reply <&3 >&3
      exec 3<&-
      [[ "$reply" =~ ^[Yy] ]] && force_confirmed="yes" || force_confirmed="no"
    else
      force_confirmed="no"
    fi
  fi
  [[ "$force_confirmed" == "yes" ]]
}

# Copy-install: walk enumerate_pairs, placing each absent or matches-recorded
# dest and warning past each diverged one instead of touching it, then write
# the manifest once with everything actually placed this run (a diverged dest
# drops out of the manifest even if a prior run recorded it). This is the
# copy replacement for the old `apply link_one` path — link_one/unlink_one/
# apply stay in place; T15 retires them once uninstall also moves off them.
install_copy() {
  load_manifest
  local src dest state backup placed=()
  while IFS=$'\t' read -r src dest; do
    state="$(classify_dest "$dest")"
    case "$state" in
      absent|matches-recorded)
        place_pair "$src" "$dest"
        placed+=("$(content_hash "$dest")  $dest")
        echo "  copy  ${dest/#$HOME/\~}"
        ;;
      diverged)
        if [[ -n "${force:-}" ]] && confirm_force; then
          backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
          if [[ -d "$dest" ]]; then
            cp -R "$dest" "$backup"
          else
            cp "$dest" "$backup"
          fi
          place_pair "$src" "$dest"
          placed+=("$(content_hash "$dest")  $dest")
          echo "  force ${dest/#$HOME/\~} (backed up -> ${backup/#$HOME/\~}; replaced)"
        else
          echo "  warn  ${dest/#$HOME/\~} (diverged; skipping)"
        fi
        ;;
    esac
  done < <(enumerate_pairs)
  printf '%s\n' "${placed[@]}" | write_manifest
}

# Manifest-driven uninstall: walk every recorded dest and remove exactly what
# install placed — rm -rf for a directory (skill) dest, plain rm for a file
# dest. classify_dest sorts out the awkward cases: an absent dest has nothing
# to remove, and a diverged dest (edited since install, or never ours) is left
# alone rather than clobbered. Clears the manifest once done, since whatever's
# left is either already gone or no longer ours to track. This is the copy
# replacement for the old `apply unlink_one` path — link_one/unlink_one/apply
# stay in place for T15 to retire.
install_uninstall() {
  load_manifest
  local dest state
  for dest in "${!MANIFEST[@]}"; do
    state="$(classify_dest "$dest")"
    case "$state" in
      absent)
        echo "  skip  ${dest/#$HOME/\~} (already absent)"
        ;;
      matches-recorded)
        if [[ -d "$dest" ]]; then
          rm -rf "$dest"
        else
          rm "$dest"
        fi
        echo "  rm    ${dest/#$HOME/\~}"
        ;;
      diverged)
        echo "  warn  ${dest/#$HOME/\~} (diverged; not removing)"
        ;;
    esac
  done
  rm -f "$AGENTS_HOME/.lets-lock"
  echo "  manifest -> ${AGENTS_HOME/#$HOME/\~}/.lets-lock (cleared)"
}

target="" action="install" force="" assume_yes=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)          target="claude" ;;
    --uninstall)       action="uninstall" ;;
    --force-reinstall) force=1 ;;
    --yes|-y)          assume_yes=1 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "error: unknown option '$1'" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -n "$target" ]] || { echo "error: a target is required (--claude)" >&2; usage >&2; exit 2; }

case "$action" in
  install)   install_copy ;;
  uninstall) install_uninstall ;;
esac
