---
name: companies
description: Manage the user's company watchlist - companies whose own careers pages are checked for new jobs on every hunt. Add companies (researches each careers page once, detects the ATS and records the cheapest reliable way to read its jobs), remove or pause them, list them with their last results, re-check or re-research broken ones, and run an immediate check. Use for "add company X to my list", "remove X", "my companies", "watchlist", "check my companies now", "Firmenliste".
model: sonnet
---

# JobHunter companies (watchlist)

Read `../../reference/conventions.md` and `../../reference/company-sources.md` (relative to this skill's base directory). Run `bash <plugin>/scripts/migrate.sh <ws>` first. Load `profile/companies.yaml` (create it from `<plugin>/templates/companies.example.yaml` if missing), `jobhunter.yaml`, `profile/profile.yaml`.

**One-time import:** if `jobhunter.yaml > sources.target_companies` (older setting) has entries that aren't in `companies.yaml`, add them to the research queue below (keep the old setting untouched).

**Filters:** if `jobhunter.yaml > companies.title_re` / `loc_re` are missing, build them from the profile as described in `company-sources.md` § Filters, show them to the user in one line, and save them.

Understand what the user wants (several actions in one message are fine) and do it:

## add
1. Collect the names (a list, comma-separated text, a pasted list, or a file). Accept optional hints per company (website, careers link, country).
2. Skip names already present (if `removed`/`paused`, offer to re-activate instead).
3. Research with `jobhunter:career-page-researcher` agents in parallel (≈ 5 companies per agent, max `limits.parallel_agents` agents), passing absolute plugin/workspace paths, target countries, the filters and `language.ui`.
4. Append the returned entries to `companies.yaml` (keep the file's order and the user's comments; add `added` = today). Entries the researcher couldn't resolve go in as `needs-research` with the open question — ask the user that question now.
5. Report a compact table: company · ATS · method · open jobs · matching jobs. Offer to show the matching jobs now (→ **check**).

## remove / pause / resume
- **remove** → `status: removed` (keeps history so its jobs aren't re-suggested; say "deleted for good" only if the user explicitly asks to delete — then remove the entry).
- **pause** → `status: paused` (skipped by hunts until resumed). **resume** → `status: active`.
- Confirm in one line what changed.

## list
Table of active/paused/needs-research companies: name · ATS/method · last checked · last result · status. Mention removed ones only as a count.

## check (run now)
Run the company part of the hunt for all active companies (or the ones named): exactly as `../hunt/SKILL.md` § 2 step 3b describes, then dedup with `seen.sh new`, score the new jobs and write them to Notion like a normal hunt (§3–§4). Report per company: open · matching · new.

## refresh / fix
For `needs-research` entries, entries with `failures >= 2`, entries whose `verified` is older than 90 days, or companies the user names: re-run the researcher and replace the method fields (`ats`, `method`, `board`, `search`, `list_hint`, `careers_url`, `verified`), keeping `name`, `added`, `notes` history (append a dated line to `notes`).

## edit filters
If the user wants different titles/locations for company checks, update `jobhunter.yaml > companies.title_re` / `loc_re` (show the new regex in plain words: "titles containing analyst, data, BI …").

Never touch other workspace files beyond `companies.yaml`, `jobhunter.yaml > companies` and the normal hunt outputs.
