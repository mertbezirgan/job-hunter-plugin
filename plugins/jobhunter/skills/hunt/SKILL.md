---
name: hunt
description: Discover every new job that could fit the user's profile across LinkedIn (search sweeps, recommended collections, job-alert emails), the market pack's local sources (e.g. Bundesagentur für Arbeit, Arbeitnow, StepStone, XING) and optional extra sources; deduplicate, hard-filter, score with parallel evaluator agents, and push a ranked shortlist to Notion as "Suggested". Use for "find jobs", "search new jobs", "hunt", or as part of /jobhunter:run.
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

## 4. Shortlist → Notion
1. Sort by score; take up to `limits.shortlist_size` with score ≥ `limits.min_score` (attended runs also mention the best 3 "stretch" jobs below the threshold).
2. For each shortlisted job: create `applications/<date>_<company>_<role>/job.md` (URL, source, metadata, **full JD verbatim**). Run `job-evaluator` in `full` mode for the top 10 (parallel) → `evaluation.md`; others keep the screen result in `evaluation.md`.
3. External-apply jobs: apply the aggregator rule (conventions §8) — find the employer ATS URL, store as Job URL; note "unconfirmed at employer" if not found.
4. Create Notion rows (column mapping from `jobhunter.yaml`): Role, Company, Location, Country, Work Model, Job URL, Source, Apply Type, Job Language, Score, Why, Legitimacy, Status=`Suggested`, Found, Posted, Salary, Files, Job ID, Updated.
5. Update `seen.jsonl` statuses (`suggested` / `skipped:<reason>`), `last_hunt_at`. Delete `jobs/tmp/`.

## 5. Report
Write `jobs/<date>-hunt.md`; attended: show in chat (in `language.ui`):
```
🔎 Hunt <date> · 412 scanned (LinkedIn 230 · Arbeitsagentur 120 · Arbeitnow 40 · StepStone 22) → 96 new → 31 passed → 14 suggested
 #  Score  Role — Company (City · Model · Apply)                 Why
 1   88    Data Analyst — Acme (Berlin · Hybrid · Easy Apply)     SQL+Power BI exact; gap: dbt
 …
Filtered out: 22 German C1 required · 18 location · 9 seniority · 6 agencies · …
Next: tell me the numbers to apply to (e.g. "1, 3, 5") or move them to "To Apply" in Notion.
```
Attended + the user replies with numbers → set those rows to `To Apply` and offer `/jobhunter:apply`.
