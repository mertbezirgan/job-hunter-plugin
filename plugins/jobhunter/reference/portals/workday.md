# Portal playbook: Workday

Tenants differ (labels, page count, questions). Treat this as the usual shape; always read the actual page. Workday uses `data-automation-id` attributes — `find`/`read_page` on visible labels works best; ids below are hints and may change.

## Recognise
Host `<tenant>.wd<N>.myworkdayjobs.com` (e.g. `siemens.wd3.myworkdayjobs.com`), sometimes a company domain framing it. Job URLs end in `…/job/<location>/<title>_<REQ-ID>`. **Each tenant = separate account.**

## Start
1. On the job page click **Apply**. A chooser may appear: *Autofill with Resume* · *Apply Manually* · *Use My Last Application* · (*Apply with LinkedIn/Indeed* on some tenants).
   - Known tenant with a previous application → **Use My Last Application**, then verify everything.
   - Otherwise → **Apply Manually** (more predictable). *Autofill with Resume* is acceptable but mis-parses often (merged jobs, missing dates, education as experience) — if used, verify every entry.
2. Sign-in dialog (*Sign In* / *Create Account*) → **user's step** (assisted mode). Account creation usually asks email + password + verify password + terms checkbox; some tenants then require email verification before continuing.

## Pages (progress bar at top; names vary slightly)
1. **My Information**
   - *How Did You Hear About Us?* — a search prompt with nested categories (e.g. "Job Board" → "LinkedIn"). Click the field, open the category, pick the item; typing then **Enter** searches.
   - *Have you previously worked for <Company>?* — radio, answer from `master-cv.md`.
   - Country (dropdown), legal first/last name, address lines, city, postal code, (state/region for some countries).
   - Email (prefilled from account), *Phone Device Type* (Mobile), country phone code (search prompt: type country, select), phone number without country code.
2. **My Experience**
   - *Work Experience* → **Add** per job: Job Title (exact from master CV), Company, Location, *I currently work here* checkbox, From (MM / YYYY — segmented date: click the month segment and type digits, e.g. `03` then `2022`), To, Role Description (paste the tailored CV bullets for that role as plain text).
   - *Education* → **Add**: School or University (search prompt — if the exact school isn't listed choose "Other"/type the name if free text is allowed), Degree (dropdown), Field of Study (search prompt), Overall Result/GPA (only if in source), From/To (year).
   - *Languages* → **Add**: language, *I am fluent in this language* checkbox (native/C2/C1 only), proficiency dropdowns (comprehension/overall/reading/speaking/writing) mapped from CEFR.
   - *Skills* — type a skill, press **Enter** to add; add the top 10–15 relevant real skills.
   - *Resume/CV* — **Select files** (`file-upload-input-ref`): upload the tailored CV PDF (≤ 5 MB). Some tenants have a second slot for cover letter/other documents.
   - *Websites* / *LinkedIn* — LinkedIn URL, portfolio.
3. **Application Questions** (1–3 pages) — tenant-specific: work authorization, sponsorship, salary expectation (often free text or number in local currency), notice period, willingness to relocate/travel, how you meet requirement X, consent to data retention. Use `answers.yaml`; collect unknown required ones.
4. **Voluntary Disclosures** — in the US: gender, ethnicity, veteran status; in EU tenants often only a **terms & conditions / data privacy consent** checkbox (required) and optional gender. Use `eeo` defaults ("I do not wish to answer"/"Prefer not to say").
5. **Self Identify** (US tenants) — disability form with name + date (a typed e-signature): list it in the summary; use `eeo.disability`.
6. **Review** — read the whole page back; compare with what you filled; then pre-submit summary → user **yes** → **Submit**.

## Traps
- **Save and Continue** (`bottom-navigation-next-button`) with an invalid/empty required field keeps you on the same page; an "Errors Found" banner lists the fields — fix each.
- Dropdowns accept only list selections; typing into them doesn't set a value. Search prompts need a click on the result (or Enter after the exact match is highlighted).
- Date segments: type digits only, no slashes. "To" stays empty when *I currently work here* is ticked.
- Autofill/"Use my last application" may duplicate entries — delete duplicates (trash icon on the entry).
- Session times out after inactivity; the draft is usually kept under *Candidate Home → My Applications* (in progress).
- Uploading a new resume on a known tenant can re-trigger parsing into My Experience — re-verify.
- After submit: confirmation page + email; status visible in *Candidate Home*.
