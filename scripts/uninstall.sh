#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/uninstall.sh [--dry-run] [--help]

Remove jpk-model-router only after confirming its expected Skill name.
JPK_SKILLS_DIR may override the parent Skill directory.
EOF
}

dry_run=false

while (($#)); do
  case "$1" in
    --dry-run) dry_run=true ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

skills_dir=${JPK_SKILLS_DIR:-"${HOME}/.agents/skills"}
target="$skills_dir/jpk-model-router"
skill_file="$target/SKILL.md"

if [[ ! -e "$target" && ! -L "$target" ]]; then
  echo "jpk-model-router is not installed at $target"
  exit 0
fi

if [[ -L "$target" || ! -d "$target" ]]; then
  echo "Refusing to remove an unsafe install target: $target" >&2
  exit 1
fi

if [[ -L "$skill_file" || ! -f "$skill_file" ]]; then
  echo "Refusing removal: expected SKILL.md is missing or symbolic." >&2
  exit 1
fi

if ! awk '
  NR == 1 && $0 != "---" { exit 1 }
  NR > 1 && $0 == "---" { exit found ? 0 : 1 }
  NR > 1 && $0 ~ /^[[:space:]]*name:[[:space:]]*jpk-model-router[[:space:]]*$/ { found = 1 }
  END { if (!found) exit 1 }
' "$skill_file"; then
  echo "Refusing removal: SKILL.md is not the expected jpk-model-router Skill." >&2
  exit 1
fi

if [[ "$dry_run" == true ]]; then
  echo "DRY RUN: would remove $target"
  exit 0
fi

rm -rf -- "$target"
echo "Removed jpk-model-router from $target"
