#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--force] [target_dir]\n' "$(basename "$0")"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="${SCRIPT_DIR}/templates/project"

FORCE=0
TARGET_ARG="."
TARGET_ASSIGNED=0

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "Unknown option: $arg"
      ;;
    *)
      if [[ "$TARGET_ASSIGNED" -eq 1 ]]; then
        fail "Only one target_dir is allowed."
      fi
      TARGET_ARG="$arg"
      TARGET_ASSIGNED=1
      ;;
  esac
done

if [[ "$TARGET_ARG" = /* ]]; then
  TARGET_DIR="$TARGET_ARG"
else
  TARGET_DIR="$(pwd)/$TARGET_ARG"
fi

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

mkdir -p \
  "$TARGET_DIR/docs/brainstorms" \
  "$TARGET_DIR/docs/plans" \
  "$TARGET_DIR/docs/reviews" \
  "$TARGET_DIR/docs/solutions" \
  "$TARGET_DIR/docs/prompts"

copy_file() {
  local src="$1"
  local rel="$2"
  local dst="$TARGET_DIR/$rel"

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" && "$FORCE" -ne 1 ]]; then
    printf 'skip   %s (already exists)\n' "$rel"
    return 0
  fi

  cp "$src" "$dst"
  printf 'write  %s\n' "$rel"
}

copy_file "$TEMPLATE_ROOT/AGENTS.md" "AGENTS.md"
copy_file "$TEMPLATE_ROOT/docs/brainstorms/TEMPLATE.md" "docs/brainstorms/TEMPLATE.md"
copy_file "$TEMPLATE_ROOT/docs/plans/TEMPLATE.md" "docs/plans/TEMPLATE.md"
copy_file "$TEMPLATE_ROOT/docs/reviews/TEMPLATE.md" "docs/reviews/TEMPLATE.md"
copy_file "$TEMPLATE_ROOT/docs/solutions/TEMPLATE.md" "docs/solutions/TEMPLATE.md"
copy_file "$TEMPLATE_ROOT/docs/prompts/README.md" "docs/prompts/README.md"
copy_file "$TEMPLATE_ROOT/docs/prompts/brainstorm.md" "docs/prompts/brainstorm.md"
copy_file "$TEMPLATE_ROOT/docs/prompts/plan.md" "docs/prompts/plan.md"
copy_file "$TEMPLATE_ROOT/docs/prompts/execute.md" "docs/prompts/execute.md"
copy_file "$TEMPLATE_ROOT/docs/prompts/review.md" "docs/prompts/review.md"
copy_file "$TEMPLATE_ROOT/docs/prompts/compound.md" "docs/prompts/compound.md"

printf '\nInitialization complete.\n'
