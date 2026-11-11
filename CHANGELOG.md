# Changelog

Every push to `main` is a release (auto-update tracks commits). Newest first.

## 2026-11-11 — Codex and ChatGPT workflow
- Add a repo-local `$jobhunter` skill, `AGENTS.md`, Codex runtime/workflow guides and a portable ChatGPT prompt. Reuse the existing evaluation, writing, market and tracking resources without requiring Claude-specific tools, model aliases, Notion, or Gmail.
- Add an idempotent Python workspace initializer with opt-in integrations, unknown-safe profile defaults, private workspace ignores and original-CV preservation.
- Support applied-history import, explicit source coverage, local tracking, salary-undisclosed roles and preference-versus-hard-filter distinctions. Separate source facts, user statements and inferred search tracks.
- Add isolated bootstrap and compatibility tests, including legacy migration and 100k-row deduplication. No live account access is needed by tests.
- **Migration:** none; existing `migrate.sh` steps are reused unchanged. New workspace files are created only if missing.
- **Compatibility:** additive; existing Claude skills, plugin manifests, status vocabulary, data columns and configured workspaces are unchanged. The new Codex defaults apply to newly initialised workspaces. Existing sessions retain their settings; avoid concurrent tracker writers.

## 2026-10-25 — LinkedIn redesign fix + company watchlist
- **LinkedIn fix:** signed-in searches now redirect to the redesigned `/jobs/search-results/` page, where result cards are `div[role=button][componentkey="job-card-component-ref-<id>"]` without links, card text starts with screen-reader duplicates ("Selected, … (Verified job)"), and job pages have no description container. The playbook §4/§5 snippets now handle both layouts (componentkey ids, hidden-text removal, "About the job" text extraction), print a status line with a self-test (`EXTRACTION_BROKEN`), and the hunt must use a page-text fallback and flag "plugin needs an update" in the digest instead of silently skipping the LinkedIn sweep. Paging continues to the page limit because `sortBy=DD` is dropped (relevance order).
- **Company watchlist:** new `/jobhunter:companies` skill, `career-page-researcher` agent, `reference/company-sources.md` and `scripts/company_jobs.pl` (Greenhouse, Lever, Ashby, SmartRecruiters, Workday, Personio, Recruitee, RSS; perl + curl only). Each company is researched once (careers page, ATS, cheapest working method: api → rss → webfetch → browser) and stored in `profile/companies.yaml`; every hunt checks all active companies with the recorded method, keeps only jobs matching `jobhunter.yaml > companies.title_re/loc_re`, and prefers the company-site record over the LinkedIn copy. Broken entries are re-researched automatically after two failed checks. Setup asks for the list (Step 3b).
- **Migration:** M4 prints a one-time notice for workspaces that have the local LinkedIn workaround (`tooling_notes.linkedin_extract_2026_10`) — the note and `tools/` files are left untouched; M5 creates an empty `profile/companies.yaml`. Entries in the old `sources.target_companies` setting are imported into the watchlist the first time `/jobhunter:companies` runs (old setting kept).
- **Compatibility:** additive; no files, keys or Notion properties renamed. Sessions still on the old version keep using the old snippets until they restart.

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
