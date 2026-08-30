#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--dry-run] [--force] [--help]

Install jpk-model-router under $HOME/.agents/skills, or under the parent
directory supplied by JPK_SKILLS_DIR.
EOF
}

dry_run=false
force=false

while (($#)); do
  case "$1" in
    --dry-run) dry_run=true ;;
    --force) force=true ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo_root/skill/jpk-model-router"
skills_dir=${JPK_SKILLS_DIR:-"${HOME}/.agents/skills"}
target="$skills_dir/jpk-model-router"

for source_file in "$source_dir/SKILL.md" "$source_dir/agents/openai.yaml"; do
  if [[ ! -f "$source_file" ]]; then
    echo "Missing source file: $source_file" >&2
    exit 1
  fi
done

refuse_unsafe_target() {
  local path
  for path in "$target" "$target/SKILL.md" "$target/agents" "$target/agents/openai.yaml"; do
    if [[ -L "$path" ]]; then
      echo "Refusing symbolic link in install target: $path" >&2
      exit 1
    fi
  done
  if [[ -e "$target" && ! -d "$target" ]]; then
    echo "Install target is not a directory: $target" >&2
    exit 1
  fi
  if [[ -e "$target/agents" && ! -d "$target/agents" ]]; then
    echo "Install target has a non-directory agents entry: $target/agents" >&2
    exit 1
  fi
}

has_only_expected_entries() {
  local entry
  [[ -d "$target" ]] || return 0
  while IFS= read -r entry; do
    case "$entry" in
      SKILL.md|agents|agents/openai.yaml) ;;
      *) echo "Unexpected entry in install target: $target/$entry" >&2; return 1 ;;
    esac
  done < <(find "$target" -mindepth 1 -printf '%P\n' | LC_ALL=C sort)
}

already_current() {
  [[ -f "$target/SKILL.md" && -f "$target/agents/openai.yaml" ]] || return 1
  has_only_expected_entries || return 1
  cmp -s "$source_dir/SKILL.md" "$target/SKILL.md" &&
    cmp -s "$source_dir/agents/openai.yaml" "$target/agents/openai.yaml"
}

refuse_unsafe_target

if already_current; then
  echo "Already installed and current: $target"
  exit 0
fi

if [[ -e "$target" ]]; then
  if ! has_only_expected_entries; then
    echo "Refusing to delete unexpected target content, even with --force." >&2
    exit 1
  fi
  if [[ "$force" != true ]]; then
    echo "A different jpk-model-router target already exists: $target" >&2
    echo "Inspect it first, then rerun with --force to replace only the two expected files." >&2
    exit 1
  fi
  action="replace the two expected runtime files"
else
  action="install the two runtime files"
fi

if [[ "$dry_run" == true ]]; then
  echo "DRY RUN: would $action at $target"
  echo "DRY RUN: $target/SKILL.md"
  echo "DRY RUN: $target/agents/openai.yaml"
  exit 0
fi

umask 022
mkdir -p -- "$target/agents"
chmod 0755 -- "$target" "$target/agents"
install -m 0644 -- "$source_dir/SKILL.md" "$target/SKILL.md"
install -m 0644 -- "$source_dir/agents/openai.yaml" "$target/agents/openai.yaml"

echo "Installed jpk-model-router at $target"
