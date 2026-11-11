# Codex workflows

Use `codex-runtime.md` for tool availability, private paths and tracker semantics.
Read the relevant workflow and domain references, not every Claude skill.

## Setup

Initialise missing workspace files with `scripts/init_workspace.py`. Preserve the
original CV, extract to `profile/master-cv.md` verbatim, inspect the source pages,
then add a separate dated Confirmed additions section. Record factual provenance.
Create a short `profile/search-brief.md` that distinguishes confirmed preferences,
CV-backed strengths, tentative search tracks and unresolved questions.

Ask only the useful missing questions in small batches: role breadth, location,
work model/commute, salary target versus hard floor, availability. A user's
“anything suitable” widens the search; it does not confirm every employment type,
relocation destination or work authorization. Keep nulls for unknown facts.
Import already-applied jobs when requested. Do not require a complete interview
before useful research. Do not automatically connect services or create schedules.

## Application history

Read the user's **Applied** view, not recommendations or Saved. Follow visible
pagination up to the configured page limit; report exactly what was inspected
and whether more pages remain. Record role, company, location, canonical job URL,
stable source ID, displayed applied date/status, observation date and source view.
Never expose application history or browser dumps in tracked files.

For each verified submitted application:

1. Save evidence in `profile/application-history.md`; quote relative date labels
   if an exact calendar date is unavailable. Keep missing fields unknown.
2. Look up its source ID. New IDs can be added with `Applied`; an existing
   Suggested/To Apply/Prepared record can be advanced to Applied with evidence.
   Preserve later or terminal statuses. Adding a second source ID for a known
   job is acceptable during history import: the index retains source aliases
   and their evidence, while future `new` calls check both IDs and dedup keys.
3. If the same company/title/location already exists under another source ID,
   record the association and check the existing application's status before
   making another recommendation. Never merge two different requisitions solely
   because titles look similar; keep uncertainty visible.
4. Save patterns (role families, seniority, location/work model) as hypotheses.
   Applications show interest, not qualifications or hard preferences. Ask about
   material conflicts with current stated preferences; current intent wins.

“Apply clicked”, “application started”, a saved item or a stale posting is not
proof of submission. Do not mark it Applied without evidence. If access is
blocked, retain a pending import and don't claim duplicate coverage is complete.

## Hunt

Read `evaluation.md`, the country's market pack and `company-sources.md` when a
watchlist exists. Build a compact search matrix from the user's role families,
skills, local-language synonyms, locations and eligible remote scope. Include
adjacent work when requested. Use LinkedIn plus public employer careers/ATS and
market sources that are available; don't silently rely only on Easy Apply.

1. Check existing tracker selections and pending history warnings.
2. Discover current postings, keeping source URL, observed date and any posted
   date. A search snippet alone is not a full job description or proof of an open
   vacancy. Verify shortlisted roles on the employer page when possible.
3. Deduplicate with `seen.sh new`. Record unavailable sources separately.
4. Screen only against confirmed hard constraints, then score with the shared
   framework. Null/empty unconfirmed profile values are not a zero-year candidate,
   rejected work model, missing permit, or zero salary. Unknowns need flags.
   If work models are acceptable but unranked, their list order earns no
   differential preference points.
5. Save every scored job (`Suggested` or `Low Match`), with score and reasons in
   the hunt report/per-job evaluation. Preserve existing application states.
6. Fully evaluate the best matches; save the full JD, metadata and URLs under
   `applications/<date>_<company>_<role>/job.md`. Use safe directory names, never
   raw slash-containing titles as paths. Include IDs when needed to avoid clashes.

Report a ranked shortlist with location, work model, evidence-backed fit,
principal gap, salary evidence/confidence, application route and source links.
State search coverage and counts actually observed. Do not promise “all jobs”.
Keep strong roles with undisclosed salaries; flag the question for screening.

## Evaluate

Read `evaluation.md` and the target market pack. First extract the JD's stated
requirements and importance; then match against candidate facts. Use explicit
evidence for each critical/high requirement and honestly flag missing skills.
Unknown eligibility is not proven eligibility. Research time-sensitive employer
claims with sources. Keep research/industry/academic experience distinct.

Use the shared 0–100 score as a decision aid, not a probability of hiring. Apply
confirmed scoring notes. Save score breakdown, source dates, gaps, salary status,
legitimacy observations and verdict in `evaluation.md`. Mark partial descriptions
as provisional. Do not invent a score for an unavailable JD.

## Tailor

Read `writing-rules.md`, the market pack and the actual JD/evaluation. Use
`templates/cv.html` and `cover-letter.html` when helpful. Preserve actual titles,
dates and claims. Lead with relevant evidence; don't manufacture metrics or
upgrade academic projects to production experience. The local writing rules'
agent names are review roles, not a requirement to spawn agents.

Draft the CV, cover letter, plain-text letter and a short why-this-role answer as
needed. Run `fact_check.sh` against primary candidate sources; allow JD context
only for clearly job-related numbers. Treat this as a **numeric smoke check**:
it cannot prove that a number belongs to the right claim, and misses single-digit
claims. Review every factual statement and its provenance separately.

Perform a second pass for claim grounding, requirement coverage, clarity and
language. Use an independent reviewer only when supported and authorized;
otherwise document self-review. Revise and rerun the numeric check. Record
sources, language decision, gaps and review type in `review.md`.

Render with the available document/PDF skill or `render_pdf.sh`. Inspect rendered
pages and extract text again: page limits, no clipping/placeholders, selectable
text and correct names/dates. If rendering fails, deliver drafts marked as such;
do not say PDFs were verified. A missing salary/permit answer should not block
drafting unrelated content, but it must not be invented in a form.

## Apply

Read `form-answering.md` and the matching `portals/` playbook if needed. Verify
the job is open, avoid duplicates, and prepare accurate documents first. Use
only the available browser's supported APIs. The user handles login, account
creation, CAPTCHA and security checks. Stop on platform warnings/limits.

Fill confirmed answers and ask only for required unknowns. Skip optional sensitive
fields unless the user chose to provide them. Do not infer military status,
citizenship, clearance, start date, years with a tool or salary consent.

Immediately before submission show company/role, destination, attachments,
screening answers and consequential consents. Obtain approval for this exact
application. No final submission during scheduled runs. Verify the confirmation
page before recording Applied. If confirmation is ambiguous, record Needs Manual
and inspect status before any retry to prevent duplicate submissions.

## Sync

Only inspect email when the user requested it. Discover available tools, scope
searches to relevant applications and a time window, and retain message IDs/links
with status evidence. Match by role/job ID, not just company name. Ambiguous
messages need review; preserve later status and user notes. Inbox availability
does not imply permission to create drafts or send mail. Write local follow-up
drafts by default; use connected drafts/sending only when explicitly requested.
Do not delete, archive, label or mark unrelated mail read as part of sync.

## Interview

Use the saved JD/evaluation, current company sources and CV-backed stories.
Prepare likely technical/behavioral themes, honest gap bridges, questions for the
team, and compensation/logistics questions. Mock interviews ask one question at
a time. Feedback must distinguish practice suggestions from actual experience.
Save debriefs privately; new claimed facts need confirmation before entering the
master CV. Don't invent outcomes for a STAR story with no documented result.

## Companies

Use `company-sources.md` and `profile/companies.yaml`. Research a requested
company's official careers page and supported public ATS/feed, then record
verified source and date. Check existing active watchlist entries on hunts.
Keep source errors visible; a failed fetch is not “no vacancies”. Suggestions
are not endorsements or confirmed vacancies. Do not follow companies on the
user's LinkedIn account merely because they appear on the local watchlist.

## Insights

Use `seen.sh stats` and programmatic summaries of per-job records, not a full
history dump. Distinguish counts imported from history from applications made
since tracking began. Report funnel counts, missing outcomes and small-sample
limits. Do not invent conversion percentages when dates/statuses are incomplete.
Propose score/search changes; record them as preferences after user confirmation.

## Run

Perform requested sync (if enabled and authorized), hunt, evaluate and prepare
the configured number of top matches. A missing connector skips that step with
an explicit note. Save a dated digest with results and coverage gaps. Preparation
never implies permission to apply, email, or register accounts. Only configure
recurring work when the user asks; use app automation tools and their timezone.
