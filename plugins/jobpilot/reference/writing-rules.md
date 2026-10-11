# Writing rules — CV, cover letter, form answers, emails

Sources: career-ops (`_writing.md`, `heuristics/recruiter-side.md`, guardrails), ai-job-search (drafter/reviewer, grounding audit, requirement coverage).

## 1. Truthfulness (non-negotiable — see conventions §5)
- Every claim traces to a primary source. Allowed: select, reorder, rephrase, merge, translate, mirror the JD's terminology for things the user really did ("dashboards in Power BI" → "data visualisation (Power BI dashboards)").
- Forbidden: new employers/titles/dates/degrees/certificates/tools/metrics/team sizes/seniority; rounding numbers up; "used X" → "built X"; job titles different from master-cv (exact title per employer).
- **Requirement coverage**: every *stated* requirement is either matched with evidence or honestly bridged in the letter ("not yet in my daily toolkit; I've worked with the closely related X") — never silently ignored, never faked.

## 2. Recruiter-side risk map (internal, don't print)
Before writing, list the recruiter's likely doubts (stack? seniority? domain? logistics: location/permit/language/salary? generic application?) and the truthful evidence that addresses each. Write to remove those doubts.

## 3. Six-second clarity gate
The top third of the CV and the first paragraph of the letter must make obvious: target role, strongest matching stack/domain, one concrete outcome, (when relevant) location/permit/language fit, portfolio link if relevant.

## 4. CV rules
- Keep the real structure (same jobs, dates, education). Page limit `documents.cv_page_limit` (default: same as original; max 2).
- Tailor: headline, 2–3 line summary for this role, skills ordered by JD relevance (only real skills), bullet order inside each role (most relevant first), cut irrelevant bullets for old roles.
- Bullet formula: **Action + scope/system + tool/approach + outcome (+ proof)**. Avoid "helped / assisted / responsible for / worked on / participated in" when stronger true ownership exists. Vary verbs and lengths.
- Use the JD's exact keyword where it's truthful, also in section headings when natural.
- ATS-safe: single column, real selectable text, standard headings, no tables/columns for layout, no text in images, no hidden/white text, no keyword stuffing, contact info in body (not header/footer), plain hyphens/quotes preferred (avoid exotic Unicode).
- Market conventions (market pack §5): section names, date format, photo/personal data, language levels (CEFR).

## 5. Cover letter rules
- Length 220–380 words (market pack may differ), one page.
- P1: the specific role + a concrete hook about **this** company from sources you actually read (cite in `review.md`). P2–P3: 2–3 JD requirement → evidence pairs. P4: logistics the posting asks for (salary expectation, start date, permit, relocation, reference number) + confident close.
- Salutation to a named person if known (posting, hiring team on LinkedIn); else market default.
- No clichés: "I am writing to express my interest", "passionate", "results-oriented", "proven track record", "leveraged", "spearheaded", "synergies", "dynamic", "fast-paced", "I believe I would be a great fit", "hiermit bewerbe ich mich", "mit großem Interesse habe ich Ihre Anzeige gelesen". Prefer specifics over abstractions.
- Also produce `cover-letter.txt` (plain, for text boxes) and `why-short.txt` (≤ 600 chars "Why this company/role?").

## 6. Style calibration (optional)
If `profile/writing-style.md` exists (extracted in setup from the user's own writing samples: tone, sentence length, punctuation habits, preferred verbs, words to avoid), apply it to letters, form answers and emails — **not** to CV bullets (keep CV formal/keyword-dense). Style never changes facts.

## 7. Form answers & emails
Short, direct, truthful; same language policy; free-text "why" answers ≤ the field limit; follow-ups 60–100 words, polite, specific (role, date applied, one value line).

## 8. Quality pipeline (always, in this order)
1. Draft (application-drafter agent or tailor skill).
2. `scripts/fact_check.sh` — every number/percentage/year in the draft must appear in primary sources; output lists unmatched tokens → fix or remove.
3. Review (hiring-manager-reviewer agent, fresh context): grounding audit, requirement coverage, six-second gate, generic sentences, tone vs writing style, keyword coverage, language quality → structured edits (JSON old→new) + narrative notes.
4. Apply edits that don't require invention; re-run fact check.
5. Render PDF, read it back: page count, nothing cut off, text selectable, correct language, no placeholder `{{…}}` left.
