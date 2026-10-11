---
name: insights
description: Analyse the user's job search so far - conversion funnel, which sources, roles, work models, languages, company types and apply routes lead to responses and interviews, whether fit scores predict outcomes, recurring skill gaps across shortlisted jobs with a learning plan, and concrete changes to targeting and settings. Use for "how is my job search going", "what's working", "why am I getting rejected", "skill gaps", "insights", weekly review.
---

# JobHunter insights

Read `../../reference/conventions.md` (relative to this skill's base directory). Data: Notion database (all rows), `jobs/seen.jsonl`, application folders (`evaluation.md`, `log.md`), `interviews/`, `jobhunter.yaml`, `profile.yaml`.

Minimum data: ≥ 15 applications for funnel conclusions, ≥ 5 responses for score-vs-outcome. Below that, give descriptive stats and say conclusions are premature.

## Report (`insights/<date>.md`, summary in chat in `language.ui`)
1. **Funnel**: discovered → suggested → applied → viewed → assessment → interview → offer; rates and median days between stages; volume per week.
2. **What converts** (response/interview rate by segment, with counts — no conclusions from n < 5): source, apply route (Easy Apply vs ATS vs manual), document language (e.g. German vs English applications in Germany), work model, company size/type, title cluster, score band, days since posting at application time.
3. **Score calibration**: do higher scores lead to more responses? Suggest a new `min_score` or weight changes only with evidence; never change scoring silently — propose, then write to `profile.yaml > scoring_notes` / `jobhunter.yaml` after the user agrees.
4. **Rejection patterns**: stage of rejection; common gaps in evaluations of rejected vs advanced jobs; language-level or permit filters causing silent rejections.
5. **Skill-gap heatmap**: requirements marked ❌/⚠️ at critical/high across all shortlisted jobs (last 60 days), weighted by frequency × importance; "already covered" list. For the top 3–5 gaps, a learning plan with concrete resources found via WebSearch (prefer free/official; include German-language course options like Goethe/VHS if German is a gap) and a time estimate. Mark resources as suggestions, not endorsements.
6. **Pipeline hygiene**: stale `Applied` rows (> 21 days, no response) → mark as likely ghosted (propose, don't auto-change); `Needs Manual` items waiting; follow-ups due.
7. **Recommendations** (max 5, concrete): e.g. "Add 'Analytics Engineer' to titles (12 near-misses)", "German-language applications got 3× responses — switch policy to match_posting", "Easy Apply response rate 2% vs ATS 9% — prioritise direct ATS".
Offer to apply each recommendation (one confirmation per change).
