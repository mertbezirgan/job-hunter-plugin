# LinkedIn playbook

LinkedIn's UI changes often. Prefer **URL parameters + `get_page_text` / `read_page` / `find`** over coordinate clicking. Re-discover controls with `find` when something moved; never hard-code CSS classes.

## 1. Session check
Open `https://www.linkedin.com/feed/`. Login wall, sign-in form, checkpoint or CAPTCHA → **stop**: attended runs ask the user to sign in themselves in that browser and wait; scheduled runs skip LinkedIn browser sources and say so in the report. Never type credentials.

## 2. Search URL builder
`https://www.linkedin.com/jobs/search/?keywords=<KW>&location=<LOC>&<filters>&sortBy=DD&start=<0,25,50…>`

| Filter | Param | Values |
|---|---|---|
| Date posted | `f_TPR` | `r86400` 24h · `r604800` week · `r2592000` month (any `r<seconds>` works) |
| Work model | `f_WT` | `1` on-site · `2` remote · `3` hybrid — comma-join, URL-encoded (`2%2C3`) |
| Experience | `f_E` | `1` internship · `2` entry · `3` associate · `4` mid-senior · `5` director · `6` executive |
| Job type | `f_JT` | `F` full-time · `P` part-time · `C` contract · `T` temporary · `I` internship · `O` other |
| Easy Apply only | `f_AL` | `true` — **not** by default (we want every option) |
| Under 10 applicants | `f_EA` | `true` — optional "early applicant" sweep |
| Distance | `distance` | miles: `10`, `25`, `50`, `100` (convert from `targets.commute_radius_km`) |
| Location id | `geoId` | after the first search with `location=<text>`, read `geoId` from the resulting URL and cache it in `jobhunter.yaml > linkedin.geo_ids` |
| Sort | `sortBy` | `DD` newest · `R` relevance |
| Company | `f_C` | company ids (for target-company sweeps) |

Window: since `jobhunter.yaml > last_hunt_at` (min 24 h, max 30 days). First run: past week.

## 3. Coverage strategy ("find every option")
Cartesian sweep, deduplicating as you go:
- **Keywords**: every title in `targets.titles` + `targets.title_synonyms` + market-pack vocabulary variants (local language, gendered forms, seniority variants, abbreviations) + 1–3 **skill queries** (e.g. `"Power BI" SQL`) — odd titles hide good jobs. Use boolean OR to batch close synonyms: `"Data Analyst" OR "BI Analyst" OR Datenanalyst`.
- **Locations**: each `targets.locations` entry; for remote acceptance add country-wide (`location=Germany&f_WT=2`) and, if `targets.remote_scope` allows, `European Union` / `EMEA`.
- **Work model**: one query per accepted model when result counts are high (> 200) — more complete than a combined filter.
- **Pagination**: `start=25,50,…` until a page yields no new jobs or `limits.max_pages_per_query` (default 6) is reached.
- **LinkedIn feeds** (signed in): `/jobs/collections/recommended/`, `/jobs/collections/easy-apply/`, `/jobs/collections/remote-jobs/` (if remote allowed), `/jobs/collections/hiring-in-network/`, `/jobs/collections/top-applicant/` (Premium only — skip silently if unavailable).
- **Job-alert emails** (Gmail): `from:(jobalerts-noreply@linkedin.com OR jobs-noreply@linkedin.com) newer_than:<n>d` → extract ids from `/jobs/view/<id>` links.
- **Coverage check**: after the sweep, if a query returned 0 results, try a broader variant once (drop seniority word, widen distance) and log it.

## 4. Extracting results
On a results page use `get_page_text`/`read_page` on the list. Capture per card: job id (`/jobs/view/<id>` or `currentJobId=`), title, company, location line, work-model hint, posted time, "Easy Apply" badge, "Promoted", applicant count, "Actively recruiting", "Be an early applicant". Skip ids already in `seen.jsonl`.

## 5. Job detail — loading guard (from career-ops)
Open `https://www.linkedin.com/jobs/view/<id>/`. **One attempt per job per run**: if the description is still a loading skeleton, scroll it into view, wait ≤ 5 s once, read again; if still unreadable → mark "JD unavailable", try the employer's careers page (aggregator rule), else leave for the user. Never retry via guest endpoints or workarounds.
Capture: full "About the job" text (verbatim), seniority, employment type, apply type (Easy Apply vs "Apply" with external link → follow once to read the destination domain), "No longer accepting applications", salary if shown, company size/industry, hiring-team/poster name (for the cover letter salutation).
For hard-filter pre-pass use card data only; open detail pages only for survivors.

## 6. Easy Apply flow
1. Click **Easy Apply**. A modal opens with steps (Contact info → Resume → Additional questions → Review). Steps vary; read each step's text before acting.
2. **Contact info**: check prefilled email/phone match `profile.yaml`; select via dropdowns.
3. **Resume**: upload `applications/<folder>/<First>_<Last>_CV_<Company>.pdf` with the browser's file-upload tool on the `input[type=file]` ("Upload resume"). If upload is impossible with the current tool, stop that application → `Needs Manual (CV upload)`; never send the generic CV silently.
4. **Cover letter** upload/text field (if present): PDF or paste `cover-letter.txt`.
5. **Questions**: per `reference/form-answering.md`. Unknown required question → collect for the pre-submit summary; don't guess.
6. **Review** step: read back every field; untick "Follow <company>" unless `preferences.follow_companies`.
7. Pre-submit summary → explicit "yes" → **Submit application** → confirm "Your application was sent" (or "Applied" badge). Close the post-submit dialog.
8. If the user says skip: close the modal and choose **Discard** (not Save).

## 7. External "Apply"
Click **Apply** → note the destination host. Classify:
- **No account usually**: Greenhouse (`boards.greenhouse.io`, `job-boards.greenhouse.io`), Lever (`jobs.lever.co`), Ashby (`jobs.ashbyhq.com`), Workable (`apply.workable.com`), Personio (`*.jobs.personio.de/.com`), Join (`join.com`), Recruitee (`*.recruitee.com`), Teamtailor, SmartRecruiters (sometimes), Softgarden (sometimes) → fill like Easy Apply.
- **Account usually required**: Workday (`myworkdayjobs.com`), SAP SuccessFactors, Taleo, iCIMS, rexx, Kariyer.net, d.vinci (sometimes) → `Needs Manual (account required)`, leave tab open, documents ready.
- Look-alike hosts (`greenhouse.io.evil.com`, `evil-lever.co`) or unknown hosts asking for unusual data (ID scans, bank details, fees) → stop, legitimacy red flag.

## 8. Stop signals
"You've reached the daily Easy Apply limit", "unusual activity", "Let's do a quick security check", HTTP 429, repeated blank pages, forced logout → stop the whole run, report, don't retry today.
