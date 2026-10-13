---
name: evaluate
description: Deep evaluation of a single job posting (link or pasted text) - fit score with two-pass requirement matching, gaps with honest bridges, compensation check, customisation plan, interview themes and posting-legitimacy signals - saved to the application folder and the Notion tracker. Use for "evaluate this job", "is this a good fit", "should I apply", or a pasted job link.
model: sonnet
---

# JobHunter evaluate

Read `../../reference/conventions.md` and `../../reference/evaluation.md` (relative to this skill's base directory) and the relevant market pack.

1. **Get the posting**: LinkedIn link → browser (playbook §5 loading guard); ATS/company link → WebFetch (if blocked, browser); pasted text → use as is (note: liveness unverified). Prefer the employer's own posting over an aggregator copy and mention material differences (title level, location, salary).
2. **Dedup**: `printf "<id>
" | bash <plugin>/scripts/seen.sh lookup <ws>`; if known, find its Notion row by Job ID (one query) and reuse its folder and row.
3. Create/update `applications/<date>_<company>_<role>/job.md` (full JD verbatim, URL, metadata).
4. If the company brief is missing or stale, run `jobhunter:company-researcher` (purpose `evaluation`) in parallel with step 5.
5. Run `jobhunter:job-evaluator` in `full` mode (or do it inline for a single job if agents are unavailable) → `evaluation.md`.
6. Show the user (in `language.ui`): score + band + recommendation, legitimacy tier, the requirement table (critical/high rows), top gaps with bridges, salary view, 3 interview themes. Keep it to one screen.
7. Notion: create or update the row (Status `Suggested` unless it already is further along; Score, Why, Legitimacy, Files).
8. Offer next steps: "Prepare CV + letter" (`/jobhunter:tailor`), "Apply now" (`/jobhunter:apply`), or "Skip" (Status `Skipped`, reason in Next Action).
If the user disagrees with the score, ask why and store the lesson in `profile.yaml > scoring_notes`.
