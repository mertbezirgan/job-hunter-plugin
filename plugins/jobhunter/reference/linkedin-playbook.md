# LinkedIn playbook

LinkedIn's UI changes often. Navigate with **URL parameters**, read pages with the **extraction snippets in §4–§5** (javascript_tool), and use `find` / a scoped `read_page` only to locate controls you must click. Never hard-code coordinates; if a snippet stops matching, fall back to `get_page_text` and report it.

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

## 4. Extracting results — use the extraction snippet (token rule)
Do **not** read result pages with `read_page` (~17k tokens/page) or `get_page_text` (~2.5k). Run this snippet with the browser's `javascript_tool` on every results page; it scrolls the (lazy-loaded) list and returns one compact TSV line per job (~25 tokens/job): `id  title  company  location  (empty url — seen.sh derives linkedin.com/jobs/view/<id>/)  flags`. The first five columns are exactly what `scripts/seen.sh` expects, so append the output to `jobs/tmp/linkedin.tsv` with a shell heredoc. Works on logged-in and logged-out pages and in any UI language. If your browser tool does not accept top-level `await`, wrap the code in `(async () => { … })()`.
```js
const first = document.querySelector('[data-occludable-job-id],[data-job-id],.base-card,a[href*="/jobs/view/"]');
let box = first; while (box && box !== document.body && !(box.scrollHeight > box.clientHeight + 50 && /(auto|scroll)/.test(getComputedStyle(box).overflowY))) box = box.parentElement;
const sc = (box && box !== document.body) ? box : document.scrollingElement;
for (let i = 0; i < 12; i++) { sc.scrollBy(0, 700); await new Promise(r => setTimeout(r, 250)); }
const out = new Map();
for (const el of document.querySelectorAll('[data-occludable-job-id],[data-job-id],.base-card,li:has(a[href*="/jobs/view/"])')) {
  const a = el.querySelector('a[href*="/jobs/view/"]');
  const id = el.getAttribute('data-occludable-job-id') || el.getAttribute('data-job-id')
    || (el.getAttribute('data-entity-urn') || '').split(':').pop()
    || (a && (a.href.match(/view\/(?:[^/?]*-)?(\d{6,})/) || [])[1]);
  if (!id || !/^\d+$/.test(id) || out.has(id)) continue;
  const lines = [...new Set(el.innerText.split('\n').map(s => s.replace(/\t/g, ' ').trim()).filter(Boolean))];
  if (!lines.length) continue;
  out.set(id, ['li:' + id, lines[0], lines[1] || '', lines[2] || '', '', lines.slice(3).join(' | ').slice(0, 160)].join('\t'));
}
`${out.size} jobs\n` + [...out.values()].join('\n');
```
Sanity check: if the count is 0 but the page clearly shows jobs (or columns look shifted), LinkedIn changed its markup — fall back to `get_page_text` for that page, and note it in the run report so the snippet can be fixed. Flags column holds badges such as "Promoted", "Easy Apply", "Be an early applicant", posted time, applicant count.
Then dedup: `bash <plugin>/scripts/seen.sh new <ws> < jobs/tmp/linkedin.tsv > jobs/tmp/linkedin-new.tsv` (prints a one-line summary; only new jobs continue).

The same pattern works for other browser-only boards (StepStone, XING…): replace the selector with the board's job-link pattern from the market pack and build the same TSV (prefix ids with the source, e.g. `st:`, `xi:`).

## 5. Job detail — extraction snippet + loading guard (from career-ops)
Open `https://www.linkedin.com/jobs/view/<id>/` and run this snippet (≈ the description's size, typically 500–1,500 tokens, instead of ~17k for `read_page`):
```js
await new Promise(r => setTimeout(r, 1500));
const q = s => document.querySelector(s);
const txt = el => el ? el.innerText.replace(/\n{3,}/g, '\n\n').trim() : '';
const desc = txt(q('#job-details, .jobs-description__content, .jobs-box__html-content, .show-more-less-html__markup, .description__text'));
const top = txt(q('.job-details-jobs-unified-top-card__container--two-pane, .jobs-unified-top-card, .job-details-jobs-unified-top-card__primary-description-container, .top-card-layout__entity-info'));
const btn = [...document.querySelectorAll('button, a')].find(b => /easy apply|einfach bewerben|kolay başvuru|^apply|^bewerben|^başvur/i.test(((b.getAttribute('aria-label') || '') + ' ' + b.innerText).trim()));
JSON.stringify({ id: (location.href.match(/view\/(\d+)/) || [])[1], title: txt(q('h1')), top: top.slice(0, 700),
  apply: btn ? ((btn.getAttribute('aria-label') || btn.innerText).trim().slice(0, 80)) : 'none',
  closed: /no longer accepting applications|nimmt keine bewerbungen mehr an|artık başvuru kabul etmiyor/i.test(document.body.innerText),
  hiring_team: txt(q('.hirer-card__hirer-information, .job-details-people-who-can-help__section--two-pane')).slice(0, 200),
  description: desc });
```
**Loading guard — one attempt per job per run:** if `description` is empty, scroll it into view, wait ≤ 5 s once and run the snippet again; still empty → try `get_page_text` once; still unreadable → mark "JD unavailable", try the employer's careers page (aggregator rule), else leave for the user. Never retry via guest endpoints or workarounds.
From the result capture: full description (verbatim — goes into `job.md` only for shortlisted jobs), seniority/employment type/salary/workplace from `top`, apply type (`Easy Apply` vs `Apply` → follow the external link once to read the destination host), `closed`, hiring-team name (for the cover-letter salutation).
For the hard-filter pre-pass use card data only; open detail pages only for survivors.

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
- **Account usually required**: Workday (`myworkdayjobs.com`), SAP SuccessFactors, Taleo, iCIMS, rexx, Kariyer.net, d.vinci (sometimes) → **assisted mode** (`reference/portals/_assisted-mode.md`): the user creates the account / signs in, Claude fills the rest. Set Apply Type `ATS (account)`.
- Look-alike hosts (`greenhouse.io.evil.com`, `evil-lever.co`) or unknown hosts asking for unusual data (ID scans, bank details, fees) → stop, legitimacy red flag.

## 8. Stop signals
"You've reached the daily Easy Apply limit", "unusual activity", "Let's do a quick security check", HTTP 429, repeated blank pages, forced logout → stop the whole run, report, don't retry today.
