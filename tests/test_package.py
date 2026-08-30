#!/usr/bin/env python3
"""Static package checks for the instruction-only router Skill."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "skill" / "jpk-model-router"
errors: list[str] = []
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    checks += 1
    if not condition:
        errors.append(message)


required_files = {
    "README.md",
    "LICENSE",
    "docs/FEATURE_SPEC.md",
    "docs/WORK_PLAN.md",
    "skill/jpk-model-router/SKILL.md",
    "skill/jpk-model-router/agents/openai.yaml",
    "scripts/install.sh",
    "scripts/uninstall.sh",
    "tests/test_package.py",
    "tests/test_install.sh",
    "evals/routing-cases.md",
    "evals/results.template.md",
    ".github/workflows/validate.yml",
}

for relative in sorted(required_files):
    check((ROOT / relative).is_file(), f"missing required file: {relative}")

skill = (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")
openai_yaml = (SKILL_DIR / "agents" / "openai.yaml").read_text(encoding="utf-8")

frontmatter = re.match(r"\A---\n(?P<body>.*?)\n---\n", skill, re.DOTALL)
check(frontmatter is not None, "SKILL.md must start with YAML front matter")
frontmatter_text = frontmatter.group("body") if frontmatter else ""

name_match = re.search(r"^name:\s*(.+?)\s*$", frontmatter_text, re.MULTILINE)
description_match = re.search(
    r"^description:\s*(.+?)\s*$", frontmatter_text, re.MULTILINE
)
check(bool(name_match and name_match.group(1) == "jpk-model-router"), "wrong Skill name")
description = description_match.group(1) if description_match else ""
check(
    len(description) >= 80
    and "GPT-5.6" in description
    and "reasoning effort" in description
    and "$jpk-model-router" in description,
    "description must state the specific router, model family, effort, and invocation",
)

check(
    'display_name: "J.P Codex Model Router"' in openai_yaml,
    "openai.yaml display name is missing",
)
check(
    'short_description: "Route Codex work across Luna, Terra, and Sol"'
    in openai_yaml,
    "openai.yaml short description is missing",
)
check(
    "$jpk-model-router" in openai_yaml,
    "openai.yaml default prompt must explicitly mention the Skill",
)
check(
    re.search(r"^\s*allow_implicit_invocation:\s*false\s*$", openai_yaml, re.MULTILINE)
    is not None,
    "implicit invocation must be disabled",
)
check("dependencies:" not in openai_yaml, "runtime must not declare dependencies")

allowed_models = {
    "gpt-5.6-luna",
    "gpt-5.6-terra",
    "gpt-5.6-sol",
}
model_ids = set(re.findall(r"\bgpt-[0-9]+(?:\.[0-9]+)+(?:-[a-z0-9-]+)?\b", skill))
check(model_ids == allowed_models, f"unexpected routing model IDs: {sorted(model_ids)}")

route_rows = re.findall(
    r"^\|\s*(L0|L1|T0|T1|S0|S1)\s*\|\s*`([^`]+)`\s*\|\s*`([^`]+)`",
    skill,
    re.MULTILINE,
)
actual_routes = {route: (model, effort) for route, model, effort in route_rows}
expected_routes = {
    "L0": ("gpt-5.6-luna", "low"),
    "L1": ("gpt-5.6-luna", "medium"),
    "T0": ("gpt-5.6-terra", "medium"),
    "T1": ("gpt-5.6-terra", "high"),
    "S0": ("gpt-5.6-sol", "high"),
    "S1": ("gpt-5.6-sol", "xhigh"),
}
check(actual_routes == expected_routes, f"routing table mismatch: {actual_routes}")
check(
    {effort for _, effort in actual_routes.values()}
    == {"low", "medium", "high", "xhigh"},
    "automatic routes must use only low, medium, high, and xhigh",
)

lower_skill = skill.lower()
required_policy_terms = {
    "route-only": "route-only behavior is missing",
    "single-writer": "single-writer rule is missing",
    "mvp_unsupported_override": "Max/Ultra rejection is missing",
    "do not execute it": "Max/Ultra automatic execution prohibition is missing",
    "routing_blocked": "honest blocked fallback is missing",
    "allow-fallback": "explicit fallback opt-in is missing",
    "model_execution_verified: unavailable": "unavailable model metadata handling is missing",
    "keep `requested` and `verified` distinct": "requested/verified distinction is missing",
}
for term, message in required_policy_terms.items():
    check(term in lower_skill, message)
check(
    re.search(r"(?:do not|never[^\n]*)\s+invoke\s+`?jpk-model-router`?", lower_skill)
    is not None,
    "recursion prevention is missing",
)

banned_runtime_terms = ("opencrab", "fable", "ontology pack", "alexai")
runtime_text = (skill + "\n" + openai_yaml).lower()
for term in banned_runtime_terms:
    check(term not in runtime_text, f"unrelated project term leaked into runtime: {term}")

runtime_files = {
    path.relative_to(SKILL_DIR).as_posix()
    for path in SKILL_DIR.rglob("*")
    if path.is_file()
}
check(
    runtime_files == {"SKILL.md", "agents/openai.yaml"},
    f"runtime package must contain exactly two files: {sorted(runtime_files)}",
)
runtime_size = sum((SKILL_DIR / relative).stat().st_size for relative in runtime_files)
check(runtime_size <= 20 * 1024, f"runtime package exceeds 20KB: {runtime_size} bytes")
check(len(skill.splitlines()) <= 300, "SKILL.md exceeds 300 lines")

markdown_link = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
for markdown_file in ROOT.rglob("*.md"):
    text = markdown_file.read_text(encoding="utf-8")
    for raw_target in markdown_link.findall(text):
        target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        target_path = target.split("#", 1)[0]
        if not target_path:
            continue
        resolved = (markdown_file.parent / target_path).resolve()
        check(resolved.exists(), f"broken relative link in {markdown_file}: {target}")

workflow = (ROOT / ".github/workflows/validate.yml").read_text(encoding="utf-8")
for command in (
    "python3 tests/test_package.py",
    "bash tests/test_install.sh",
    "git diff --check",
):
    check(command in workflow, f"workflow does not run: {command}")
check("actions/checkout@v4" in workflow, "workflow must use actions/checkout@v4")
check(
    re.search(r"^permissions:\n\s+contents:\s+read\s*$", workflow, re.MULTILINE)
    is not None,
    "workflow must declare contents: read",
)

installer = (ROOT / "scripts/install.sh").read_text(encoding="utf-8")
uninstaller = (ROOT / "scripts/uninstall.sh").read_text(encoding="utf-8")
check("set -euo pipefail" in installer, "installer must use strict shell mode")
check("set -euo pipefail" in uninstaller, "uninstaller must use strict shell mode")
check("JPK_SKILLS_DIR" in installer and "JPK_SKILLS_DIR" in uninstaller, "override missing")
check("--dry-run" in installer and "--force" in installer, "installer options missing")
check("--dry-run" in uninstaller, "uninstaller dry-run missing")
for prohibited in ("sudo", "curl", ".codex/config.toml"):
    check(prohibited not in installer + uninstaller, f"prohibited installer behavior: {prohibited}")

results_template = (ROOT / "evals/results.template.md").read_text(encoding="utf-8")
check("NOT_RUN" in results_template, "forward-eval template must start unexecuted")
check("18/18" not in results_template, "unexecuted evals must not claim 18/18 PASS")

if errors:
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"PASS: package structure and policy checks ({checks} checks)")
