"""Exercise reused shell helpers on synthetic data, never the personal workspace."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "plugins/jobhunter/scripts"
git_bash = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
BASH = os.environ.get("JOBHUNTER_BASH") or (
    str(git_bash) if os.name == "nt" and git_bash.exists() else shutil.which("bash")
)


def shell_path(path):
    path = Path(path).resolve()
    if os.name == "nt" and path.drive:
        return "/" + path.drive[0].lower() + path.as_posix()[2:]
    return str(path)


@unittest.skipUnless(BASH, "Bash required; on Windows set JOBHUNTER_BASH to Git Bash")
class CompatibilityTests(unittest.TestCase):
    def setUp(self):
        # Keep child-process fixtures in the workspace on sandboxed Windows.
        scratch = ROOT / "tmp"
        scratch.mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.ws = Path(self.temp.name) / "workspace with spaces"
        (self.ws / "profile").mkdir(parents=True)
        (self.ws / "jobs").mkdir()

    def run_script(self, name, *args, stdin="", check=True):
        # awk -v interprets backslash escapes, even when Bash accepts the path.
        arguments = [shell_path(arg) if isinstance(arg, Path) else str(arg) for arg in args]
        result = subprocess.run(
            [BASH, shell_path(SCRIPTS / name), *arguments], input=stdin,
            capture_output=True, encoding="utf-8", timeout=30,
        )
        if check:
            self.assertEqual(0, result.returncode, result.stderr + result.stdout)
        return result

    def test_legacy_migration_is_idempotent_and_merges_later_writes(self):
        old_settings = self.ws / "jobpilot.yaml"
        old_settings.write_text("version: 1\ncustom: keep\n", encoding="utf-8")
        old_index = self.ws / "jobs/seen.jsonl"
        row = {"source_id": "li:11", "title": "Engineer", "company": "Example",
               "location": "Istanbul", "status": "Applied", "found": "2026-01-01"}
        old_index.write_text(json.dumps(row) + "\n", encoding="utf-8")
        self.run_script("migrate.sh", self.ws)
        self.assertEqual(old_settings.read_bytes(), (self.ws / "jobhunter.yaml").read_bytes())
        before = (self.ws / "jobs/seen.tsv").read_bytes()
        second = self.run_script("migrate.sh", self.ws)
        self.assertEqual("", second.stdout)
        self.assertEqual(before, (self.ws / "jobs/seen.tsv").read_bytes())
        self.assertIn("li:11\tApplied", self.run_script("seen.sh", "lookup", self.ws, stdin="li:11\n").stdout)
        row["source_id"] = "li:12"
        with old_index.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(row) + "\n")
        self.run_script("migrate.sh", self.ws)
        self.assertTrue(old_index.exists())
        self.assertEqual(2, len((self.ws / "jobs/seen.tsv").read_text(encoding="utf-8").splitlines()))

    def test_rediscovery_keeps_applied_and_later_statuses(self):
        candidate = "li:21\tSoftware Engineer\tExample Ltd\tIstanbul, Türkiye\thttps://example.invalid/21\n"
        self.run_script("seen.sh", "add", self.ws, "Applied", stdin=candidate)
        self.run_script("seen.sh", "add", self.ws, "Suggested", stdin=candidate)
        self.assertIn("li:21\tApplied", self.run_script("seen.sh", "lookup", self.ws, stdin="li:21\n").stdout)
        self.run_script("seen.sh", "status", self.ws, stdin="li:21\tInterview\n")
        self.run_script("seen.sh", "add", self.ws, "Applied", stdin=candidate)
        self.assertIn("li:21\tInterview", self.run_script("seen.sh", "lookup", self.ws, stdin="li:21\n").stdout)
        alias = "ats:21\tSoftware Engineer\tExample\tIstanbul\thttps://example.invalid/ats/21\n"
        self.assertEqual("", self.run_script("seen.sh", "new", self.ws, stdin=alias).stdout)

    def test_large_index_preserved_when_filtering(self):
        index = self.ws / "jobs/seen.tsv"
        with index.open("w", encoding="utf-8", newline="\n") as handle:
            for i in range(100000):
                handle.write(f"li:{i}\tcompany{i}|engineer|istanbul\t2026-01-01\t2026-01-01\tApplied\tEngineer\tCompany{i}\tIstanbul\thttps://example.invalid/{i}\n")
        before = index.stat().st_size
        candidates = "li:99999\tEngineer\tCompany99999\tIstanbul\thttps://example.invalid/99999\nats:new\tEngineer\tNewCompany\tIstanbul\thttps://example.invalid/new\n"
        output = self.run_script("seen.sh", "new", self.ws, stdin=candidates).stdout
        self.assertTrue(output.startswith("ats:new\t"))
        self.assertEqual(1, len(output.splitlines()))
        self.assertEqual(before, index.stat().st_size)
        self.assertIn("total 100000", self.run_script("seen.sh", "stats", self.ws).stdout)

    def test_number_check_flags_invented_metric(self):
        primary = self.ws / "profile/master-cv.md"
        primary.write_text("Built a Python application in 2023.\n", encoding="utf-8")
        draft = self.ws / "draft.txt"
        draft.write_text("Built a Python application in 2023.\n", encoding="utf-8")
        self.assertIn("OK:", self.run_script("fact_check.sh", draft, "--sources", primary).stdout)
        draft.write_text("Improved performance by 87%.\n", encoding="utf-8")
        result = self.run_script("fact_check.sh", draft, "--sources", primary, check=False)
        self.assertEqual(1, result.returncode)
        self.assertIn("UNGROUNDED", result.stdout)


if __name__ == "__main__":
    unittest.main()
