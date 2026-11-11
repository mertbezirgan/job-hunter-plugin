#!/usr/bin/env python3
"""Create missing Codex workspace files without replacing personal data.

Python 3.9+, standard library only. This does not extract CVs or access accounts.
"""

import argparse
from pathlib import Path


TEMPLATES = Path(__file__).resolve().parent.parent / "templates"
PRIVATE_PATTERNS = (
    "/profile/", "/applications/", "/jobs/", "/interviews/", "/companies/",
    "/insights/", "/markets/", "/jobhunter.yaml", "/jobpilot.yaml", "/private/",
    "/tmp/", "/output/", "/workspace-export/", "/*.pdf", "/*.docx",
)
SUPPORTED_CV = {".pdf", ".docx", ".txt", ".md"}


def create_file(path, content):
    """Exclusive creation also protects against an intervening writer."""
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("xb") as handle:
            handle.write(content)
    except FileExistsError:
        return False
    return True


def init_workspace(workspace, cv=None):
    workspace = Path(workspace).resolve()
    if workspace.exists() and not workspace.is_dir():
        raise ValueError("Workspace must be a directory")
    if (workspace / "jobpilot.yaml").exists() and not (workspace / "jobhunter.yaml").exists():
        raise ValueError("Legacy workspace: run migrate.sh before initialising Codex")

    # Validate/read all inputs before creating directories or files.
    files = {
        "jobhunter.yaml": (TEMPLATES / "codex-jobhunter.example.yaml").read_bytes(),
        "profile/profile.yaml": (TEMPLATES / "codex-profile.example.yaml").read_bytes(),
        "profile/answers.yaml": b"# Only confirmed screening answers belong here.\n[]\n",
        "profile/companies.yaml": (TEMPLATES / "companies.example.yaml").read_bytes(),
        "profile/portal-accounts.yaml": (TEMPLATES / "portal-accounts.example.yaml").read_bytes(),
        "jobs/seen.tsv": b"",
    }
    if cv is not None:
        source = Path(cv).resolve()
        if not source.is_file() or source.suffix.lower() not in SUPPORTED_CV:
            raise ValueError("CV must be an existing PDF, DOCX, TXT, or Markdown file")
        content = source.read_bytes()
        destination = workspace / "profile" / ("original-cv" + source.suffix.lower())
        originals = list((workspace / "profile").glob("original-cv.*"))
        if any(p != destination or p.read_bytes() != content for p in originals):
            raise ValueError("A different original CV already exists; preserve it and import the revision explicitly")
        files[str(destination.relative_to(workspace))] = content

    for relative in files:
        target = workspace / relative
        if target.exists() and not target.is_file():
            raise ValueError("Expected a file at " + str(target))
        if any(p.exists() and not p.is_dir() for p in target.parents if p != workspace.parent):
            raise ValueError("A workspace parent path is not a directory")

    workspace.mkdir(parents=True, exist_ok=True)
    ignore = workspace / ".gitignore"
    existing = ignore.read_text(encoding="utf-8") if ignore.exists() else ""
    # If negations occur, append protections after them so they cannot re-include
    # personal files. Do not rewrite or remove any existing rules.
    rules = existing.splitlines()
    last_negation = max((i for i, rule in enumerate(rules) if rule.startswith("!")), default=-1)
    effective_rules = rules[last_negation + 1:]
    missing = [rule for rule in PRIVATE_PATTERNS if rule not in effective_rules]
    if missing:
        with ignore.open("a", encoding="utf-8", newline="\n") as handle:
            if existing and not existing.endswith("\n"):
                handle.write("\n")
            handle.write("# JobHunter personal workspace (never commit)\n" + "\n".join(missing) + "\n")

    created = []
    for relative, content in files.items():
        if create_file(workspace / relative, content):
            created.append(relative)
    return created


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workspace", type=Path)
    parser.add_argument("--cv", type=Path, help="Optional original CV to copy, never overwrite")
    args = parser.parse_args()
    try:
        created = init_workspace(args.workspace, args.cv)
    except (OSError, ValueError) as exc:
        parser.exit(2, "Workspace not initialised: " + str(exc) + "\n")
    for name in created:
        print("Created " + name)
    print("Existing data preserved. Next: extract the CV and confirm search preferences.")


if __name__ == "__main__":
    main()
