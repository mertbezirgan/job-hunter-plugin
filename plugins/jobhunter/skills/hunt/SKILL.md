---
name: hunt
description: Discover every new job that could fit the user's profile across LinkedIn (search sweeps, recommended collections, job-alert emails), the market pack's local sources (e.g. Bundesagentur für Arbeit, Arbeitnow, StepStone, XING) and optional extra sources; deduplicate, hard-filter, score with parallel evaluator agents, and write every scored job to Notion ("Suggested" or "Low Match"). Use for "find jobs", "search new jobs", "hunt", or as part of /jobhunter:run.
---

# JobHunter hunt

Read (relative to this skill's base directory) `../../reference/conventions.md`, `../../reference/linkedin-playbook.md`, `../../reference/evaluation.md`, `../../reference/notion-schema.md` and the market pack(s) for `profile.yaml > market.countries`. Load `jobhunter.yaml`, `profile/profile.yaml`.

Arguments: `--scheduled`, `--since <24h|week|month>`, `--only <source>`, free-text narrowing ("remote only", "Munich only").

## 1. Plan
- Window: since `last_hunt_at` (min 24 h, max 30 days); first run: 7 days.
- Term list = titles + synonyms + market-pack vocabulary variants (local language, gendered forms) + skill queries. Location list = `targets.locations` + remote scope entries.
- Split sources:
  - **Browser (main thread, sequential)**: LinkedIn searches, LinkedIn collections, browser-only market sources (e.g. StepStone, XING), `extra_sites`.
  - **Agents (parallel, background)**: `jobhunter:job-scout` for API/feed sources from the market pack (e.g. Arbeitsagentur, Arbeitnow), `target_companies` ATS boards, JobSpy. Give each scout absolute paths, the term/location lists, window, source list and output file `jobs/tmp/scout-<source>.json`.
  - **Gmail**: LinkedIn job-alert emails (and any other job alert senders the market pack lists).
- Attended: print the plan in one line, no confirmation needed.

## 2. Collect
1. Launch the scout agents first (they run while you browse).
2. LinkedIn: session check → sweep per playbook §3 → extract cards (§4). 2–5 s pause between pages. Append candidates to `jobs/tmp/linkedin.json`.
3. Browser-only market sources: same pattern, using the URL patterns in the market pack.
4. Gmail alerts: extract ids → add as LinkedIn candidates.
5. Wait for scouts; merge all candidates; cross-source dedup (conventions §7); drop anything in `seen.jsonl` or already in Notion (query by Job ID / URL). Append every new candidate to `seen.jsonl` (`{"source_id","title","company","location","url","found","status":"new"}`).

## 3. Filter & score
1. Cheap hard filters on card data (evaluation.md Stage 1).
2. Survivors without a usable description: fetch details — LinkedIn detail pages in the browser (playbook §5 loading guard), others via WebFetch. Keep the JD text.
3. Score with `jobhunter:job-evaluator` agents in `screen` mode: batches of ~15 jobs, up to `limits.parallel_agents` in parallel; pass profile/master-cv/market pack paths and `language.ui`.
4. Language/eligibility flags from the evaluator are kept for the Notion "Why".

## 4. Every scored job → Notion (do this IMMEDIATELY after scoring, before any further work)
The user wants to see everything that was found, not only what was applied to. Writing to Notion is therefore not optional and happens before the expensive steps, so a long or interrupted run never loses it.
1. For **every job that passed the hard filters and got a score**, create a Notion row (column mapping from `jobhunter.yaml`): Role, Company, Location, Country, Work Model, Job URL, Source, Apply Type, Job Language, Score, Why, Status, Found, Posted, Salary, Job ID, Updated.
   - Status = `Suggested` when score ≥ `limits.min_score` (cap `limits.shortlist_size`; extra ones beyond the cap also `Suggested`, they just aren't pre-evaluated), otherwise `Low Match`.
   - If the database's Status property lacks the `Low Match` (or `Filtered`) option, add the option to the database schema first (existing databases created before this version don't have it).
   - If `notion.log_filtered` is true, also create rows for hard-filtered jobs with Status `Filtered` and the reason in Why (default false — those are only counted in the report).
2. **Batch the writes**: create many pages per Notion tool call (the Notion connector accepts a list of pages; use batches of ~20–25) instead of one call per job. Keep property values short.
3. **Verify**: query the database for rows with Found = today (count only) and compare with the number you meant to write; create any missing rows. Report the count.
4. Update the local index (`jobs/seen.jsonl`) statuses: `suggested` / `low-match` / `filtered:<reason>`.

## 5. Shortlist enrichment (updates existing rows)
1. Shortlist = `Suggested` rows from this run, sorted by score, up to `limits.shortlist_size`.
2. For each: create `applications/<date>_<company>_<role>/job.md` (URL, source, metadata, **full JD verbatim**). Run `job-evaluator` in `full` mode for the top 10 (parallel) → `evaluation.md`; others keep the screen result in `evaluation.md`.
3. External-apply jobs: apply the aggregator rule (conventions §8) — find the employer ATS URL; note "unconfirmed at employer" if not found.
4. **Update** (never re-create) their Notion rows: Job URL (if the employer URL was found), Legitimacy, refined Score/Why from the full evaluation, Files = folder path, Updated.
5. Update `last_hunt_at`. Delete `jobs/tmp/`.

## 6. Report
Write `jobs/<date>-hunt.md`; attended: show in chat (in `language.ui`):
```
🔎 Hunt <date> · 412 scanned (LinkedIn 230 · Arbeitsagentur 120 · Arbeitnow 40 · StepStone 22) → 96 new → 31 passed → 14 Suggested + 17 Low Match written to Notion
 #  Score  Role — Company (City · Model · Apply)                 Why
 1   88    Data Analyst — Acme (Berlin · Hybrid · Easy Apply)     SQL+Power BI exact; gap: dbt
 …
Filtered out: 22 German C1 required · 18 location · 9 seniority · 6 agencies · …
Next: tell me the numbers to apply to (e.g. "1, 3, 5") or move them to "To Apply" in Notion.
```
Attended + the user replies with numbers → set those rows to `To Apply` and offer `/jobhunter:apply`.
