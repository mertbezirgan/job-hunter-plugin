# Changelog

Every push to `main` is a release (auto-update tracks commits). Newest first.

## 2026-10-13 — Token efficiency: extraction snippets, seen index, Sonnet defaults
- LinkedIn search and job pages are read with small extraction scripts (`reference/linkedin-playbook.md` §4–§5) instead of the full page tree: measured ~17k → ~1.5k tokens per search page and ~17k → ~1k per job page.
- New dedup index `jobs/seen.tsv` handled only by `scripts/seen.sh` (`new`, `add`, `status`, `lookup`, `reposts`, `stats`); Claude never reads the history file and Notion is no longer queried per job. 0.4 s to check 600 candidates against 100k known jobs.
- Notion is read once per run (rows edited since the last hunt) plus a one-time import of all existing rows into the index.
- All agents and the hunt/run/sync/insights/evaluate/tailor skills run on Sonnet (`model: sonnet`); setup, apply and interview keep the session's model.
- New `scripts/migrate.sh`, run as step 0 by every skill.
- **Migration:** M1 copies `jobpilot.yaml` → `jobhunter.yaml` if only the old file exists; M2 imports `jobs/seen.jsonl` into `jobs/seen.tsv` (original kept; re-runs if an older session appends to the jsonl); M3 creates `profile/portal-accounts.yaml` if missing. One-time Notion import fills the index with every job already in Notion (`index.notion_imported_at`).
- **Compatibility:** no files deleted or renamed. Users with open sessions on the old version keep writing `seen.jsonl`; the next new session merges those writes.

## 2026-10-13 — Every scored job goes to Notion
- Hunt writes all scored jobs right after scoring (`Suggested` / new `Low Match`, optional `Filtered` via `notion.log_filtered`), batched, with a row-count check.
- **Migration:** none; the `Low Match`/`Filtered` options are added to the Notion Status property on first use.
- **Compatibility:** existing rows untouched.

## 2026-10-12 — Assisted mode for account-based portals
- Workday, SuccessFactors, Taleo, iCIMS, rexx, d.vinci, Softgarden, SmartRecruiters playbooks; the user does the account/sign-in step, Claude fills the rest.
- **Migration:** `profile/portal-accounts.yaml` created on first use.
- **Compatibility:** additive.

## 2026-10-11 — Rename jobpilot → jobhunter, auto-update, macOS fixes
- Plugin, marketplace and commands renamed to `jobhunter`; `version` removed from `plugin.json` so every commit updates; `fact_check.sh` made BSD-sed compatible.
- **Migration:** `jobpilot.yaml` → `jobhunter.yaml` (now automated by migrate.sh M1).
- **Compatibility:** users of the old `jobpilot` install had to switch the settings entry once.
