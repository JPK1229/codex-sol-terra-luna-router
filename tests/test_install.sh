#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
install_script="$repo_root/scripts/install.sh"
uninstall_script="$repo_root/scripts/uninstall.sh"
source_skill="$repo_root/skill/jpk-model-router"
original_home=${HOME}
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

export HOME="$tmp/home"
export JPK_SKILLS_DIR="$tmp/skills"
mkdir -p -- "$HOME"
target="$JPK_SKILLS_DIR/jpk-model-router"

case "$target" in
  "$tmp"/*) ;;
  *) echo "FAIL: test target escaped the temporary directory" >&2; exit 1 ;;
esac
[[ "$HOME" != "$original_home" ]]

bash "$install_script" --dry-run
[[ ! -e "$target" ]]

bash "$install_script"
cmp -s "$source_skill/SKILL.md" "$target/SKILL.md"
cmp -s "$source_skill/agents/openai.yaml" "$target/agents/openai.yaml"

actual_files=$(find "$target" -type f -printf '%P\n' | LC_ALL=C sort)
expected_files=$'SKILL.md\nagents/openai.yaml'
[[ "$actual_files" == "$expected_files" ]]
[[ $(stat -c '%a' "$target/SKILL.md") == 644 ]]
[[ $(stat -c '%a' "$target/agents/openai.yaml") == 644 ]]

touch -d '@946684800' "$target/SKILL.md"
mtime_before=$(stat -c '%Y' "$target/SKILL.md")
bash "$install_script"
mtime_after=$(stat -c '%Y' "$target/SKILL.md")
[[ "$mtime_before" == "$mtime_after" ]]
cmp -s "$source_skill/SKILL.md" "$target/SKILL.md"

printf '%s\n' '---' 'name: conflicting-skill' '---' > "$target/SKILL.md"
if bash "$install_script"; then
  echo "FAIL: conflicting install succeeded without --force" >&2
  exit 1
fi
grep -q '^name: conflicting-skill$' "$target/SKILL.md"

bash "$install_script" --force
cmp -s "$source_skill/SKILL.md" "$target/SKILL.md"
cmp -s "$source_skill/agents/openai.yaml" "$target/agents/openai.yaml"

bash "$uninstall_script" --dry-run
[[ -d "$target" ]]
bash "$uninstall_script"
[[ ! -e "$target" ]]

mkdir -p -- "$target/agents"
printf '%s\n' '---' 'name: not-jpk-model-router' '---' > "$target/SKILL.md"
printf '%s\n' 'policy:' '  allow_implicit_invocation: false' > "$target/agents/openai.yaml"
if bash "$uninstall_script"; then
  echo "FAIL: uninstaller removed an unexpected Skill" >&2
  exit 1
fi
[[ -d "$target" ]]
grep -q '^name: not-jpk-model-router$' "$target/SKILL.md"

echo "PASS: installer and uninstaller scenarios use only $tmp"
