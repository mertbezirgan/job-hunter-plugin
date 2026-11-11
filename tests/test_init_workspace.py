import importlib.util
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "init_workspace", ROOT / "plugins/jobhunter/scripts/init_workspace.py"
)
bootstrap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bootstrap)


class WorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.workspace = self.root / "Istanbul workspace"

    def snapshot(self):
        return {p.relative_to(self.workspace): p.read_bytes()
                for p in self.workspace.rglob("*") if p.is_file()}

    def test_repeat_preserves_personal_edits_history_and_original(self):
        cv = self.root / "Örnek CV.pdf"
        cv.write_bytes(b"%PDF-test-fixture")
        bootstrap.init_workspace(self.workspace, cv)
        (self.workspace / "profile/profile.yaml").write_text("custom: confirmed\n", encoding="utf-8")
        (self.workspace / "jobs/seen.tsv").write_text("li:1\tkey\tdate\tdate\tApplied\trole\tcompany\tcity\turl\n", encoding="utf-8")
        before = self.snapshot()
        self.assertEqual([], bootstrap.init_workspace(self.workspace, cv))
        self.assertEqual(before, self.snapshot())
        self.assertEqual(cv.read_bytes(), (self.workspace / "profile/original-cv.pdf").read_bytes())

    def test_missing_cv_does_not_create_workspace(self):
        with self.assertRaises(ValueError):
            bootstrap.init_workspace(self.workspace, self.root / "missing.pdf")
        self.assertFalse(self.workspace.exists())

    def test_different_cv_refused_without_changes(self):
        cv = self.root / "original.txt"
        cv.write_text("original facts", encoding="utf-8")
        bootstrap.init_workspace(self.workspace, cv)
        before = self.snapshot()
        cv.write_text("new facts", encoding="utf-8")
        with self.assertRaises(ValueError):
            bootstrap.init_workspace(self.workspace, cv)
        self.assertEqual(before, self.snapshot())

    def test_existing_legacy_settings_require_migration(self):
        self.workspace.mkdir()
        (self.workspace / "jobpilot.yaml").write_text("custom: old\n", encoding="utf-8")
        before = self.snapshot()
        with self.assertRaises(ValueError):
            bootstrap.init_workspace(self.workspace)
        self.assertEqual(before, self.snapshot())

    def test_protects_data_after_existing_ignore_negations(self):
        self.workspace.mkdir()
        ignore = self.workspace / ".gitignore"
        existing = "/profile/\n!/profile/\n# Keep this user's rule\n*.scratch\n"
        ignore.write_text(existing, encoding="utf-8")
        bootstrap.init_workspace(self.workspace)
        result = ignore.read_text(encoding="utf-8")
        self.assertTrue(result.startswith(existing))
        self.assertGreater(result.rfind("/profile/"), result.index("!/profile/"))
        before = self.snapshot()
        bootstrap.init_workspace(self.workspace)
        self.assertEqual(before, self.snapshot())


if __name__ == "__main__":
    unittest.main()
