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
| Sort | `sortBy` | `DD` newest · `R` relevance — **dropped by the redesigned page** (see note below) |
| Company | `f_C` | company ids (for target-company sweeps) |

Window: since `jobhunter.yaml > last_hunt_at` (min 24 h, max 30 days). First run: past week.

**Redesigned search (Oct 2026, signed-in accounts):** `/jobs/search/?…` URLs redirect to `/jobs/search-results/?…` ("AI-powered job search"). Paging with `start=0,25,50…` still works (25 cards per page). `sortBy=DD` is dropped in the redirect, so results come back in relevance order: don't stop paging just because one page has no *new* jobs — page until `limits.max_pages_per_query` or until a page returns fewer than 25 cards. After the first redirect, check whether `f_TPR` survived in the final URL; if not, rely on the posted time in the flags column plus `seen.sh` dedup, and note it in the report.

## 3. Coverage strategy ("find every option")
Cartesian sweep, deduplicating as you go:
- **Keywords**: every title in `targets.titles` + `targets.title_synonyms` + market-pack vocabulary variants (local language, gendered forms, seniority variants, abbreviations) + 1–3 **skill queries** (e.g. `"Power BI" SQL`) — odd titles hide good jobs. Use boolean OR to batch close synonyms: `"Data Analyst" OR "BI Analyst" OR Datenanalyst`.
- **Locations**: each `targets.locations` entry; for remote acceptance add country-wide (`location=Germany&f_WT=2`) and, if `targets.remote_scope` allows, `European Union` / `EMEA`.
- **Work model**: one query per accepted model when result counts are high (> 200) — more complete than a combined filter.
- **Pagination**: `start=25,50,…` until a page returns fewer than 25 cards or `limits.max_pages_per_query` (default 6) is reached. (With date sorting, which still works on the classic page, you may also stop once a page yields no new jobs; on the redesigned page results are relevance-ordered, so keep paging.)
- **LinkedIn feeds** (signed in): `/jobs/collections/recommended/`, `/jobs/collections/easy-apply/`, `/jobs/collections/remote-jobs/` (if remote allowed), `/jobs/collections/hiring-in-network/`, `/jobs/collections/top-applicant/` (Premium only — skip silently if unavailable).
- **Job-alert emails** (Gmail): `from:(jobalerts-noreply@linkedin.com OR jobs-noreply@linkedin.com) newer_than:<n>d` → extract ids from `/jobs/view/<id>` links.
- **Coverage check**: after the sweep, if a query returned 0 results, try a broader variant once (drop seniority word, widen distance) and log it.

## 4. Extracting results — use the extraction snippet (token rule)
Do **not** read result pages with `read_page` (~17k tokens/page) or `get_page_text` (~2.5k). Run this snippet with the browser's `javascript_tool` on every results page; it scrolls the (lazy-loaded) list and returns a status line plus one compact TSV line per job (~25 tokens/job): `id  title  company  location  (empty url — seen.sh derives linkedin.com/jobs/view/<id>/)  flags`. The first five columns are exactly what `scripts/seen.sh` expects, so append the job lines (not the status line) to `jobs/tmp/linkedin.tsv` with a shell heredoc. It handles both layouts — the classic `/jobs/search/` page (logged out / older accounts) and the redesigned `/jobs/search-results/` page (Oct 2026: cards are `div[role=button][componentkey="job-card-component-ref-<id>"]`, no links) — removes screen-reader-only duplicate lines ("Selected, … (Verified job)") so columns don't shift, and works in any UI language. If your browser tool does not accept top-level `await`, wrap the code in `(async () => { … })()`.
```js
const CARD_SEL = '[componentkey^="job-card-component-ref-"],[data-occludable-job-id],[data-job-id],.base-card,li:has(a[href*="/jobs/view/"])';
const first = document.querySelector(CARD_SEL);
let box = first; while (box && box !== document.body && !(box.scrollHeight > box.clientHeight + 50 && /(auto|scroll)/.test(getComputedStyle(box).overflowY))) box = box.parentElement;
const sc = (box && box !== document.body) ? box : document.scrollingElement;
for (let i = 0; i < 12; i++) { sc.scrollBy(0, 700); await new Promise(r => setTimeout(r, 250)); }
const isHidden = e => { const cs = getComputedStyle(e), r = e.getBoundingClientRect();
  return cs.display === 'none' || cs.visibility === 'hidden' || /visually-hidden|sr-only|a11y-text/.test(e.className || '')
    || (cs.position === 'absolute' && (r.width <= 2 || r.height <= 2)) || cs.clipPath === 'inset(50%)'; };
const SR = /^(selected|ausgewählt|seçili)\b|\((verified job|verifizierte stelle|doğrulanmış iş ilanı)\)|with verification$|mit verifizierung$/i;
const visibleLines = el => {   // card text without screen-reader-only duplicates
  const hidden = [...el.querySelectorAll('*')].filter(isHidden);
  hidden.forEach(h => { h.dataset.jhd = h.style.display; h.style.display = 'none'; });
  const t = el.innerText; hidden.forEach(h => { h.style.display = h.dataset.jhd; delete h.dataset.jhd; });
  const ls = [...new Set(t.split('\n').map(s => s.replace(/\t/g, ' ').trim()).filter(s => s && !SR.test(s)))];
  return ls.filter(s => !ls.some(o => o !== s && o.length > s.length && o.startsWith(s) && SR.test(o)));
};
const out = new Map();
for (const el of document.querySelectorAll(CARD_SEL)) {
  const a = el.querySelector('a[href*="/jobs/view/"]');
  const id = ((el.getAttribute('componentkey') || '').match(/job-card-component-ref-(\d+)/) || [])[1]
    || el.getAttribute('data-occludable-job-id') || el.getAttribute('data-job-id')
    || (el.getAttribute('data-entity-urn') || '').split(':').pop()
    || (a && (a.href.match(/view\/(?:[^/?]*-)?(\d{6,})/) || [])[1]);
  if (!id || !/^\d+$/.test(id) || out.has(id)) continue;
  const lines = visibleLines(el);
  if (!lines.length) continue;
  out.set(id, ['li:' + id, lines[0], lines[1] || '', lines[2] || '', '', lines.slice(3).join(' | ').slice(0, 160)].join('\t'));
}
const probe = document.querySelectorAll('[componentkey*="job-card"],[data-job-id],[data-occludable-job-id],.base-card,.job-card-container,a[href*="/jobs/view/"],a[href*="currentJobId="]').length;
`${out.size} jobs · probe ${probe}${out.size === 0 && probe > 0 ? ' · EXTRACTION_BROKEN' : ''} · ${location.pathname}\n` + [...out.values()].join('\n');
```
**Status line and self-test.** The first line reads `<n> jobs · probe <m> · <path>`.
- Run the snippet on the **first results page of the run before anything else** (preflight). If it says `EXTRACTION_BROKEN` (0 jobs although job elements were found), or the columns look wrong (company names in the title column, empty titles), LinkedIn changed its markup again: for this run read result pages with `get_page_text` instead (≈2.5k tokens/page) and parse id/title/company/location from it yourself, and put this line at the **top** of the run digest and hunt report: `⚠️ LinkedIn page layout changed — extraction snippet failed, used page-text fallback (more tokens). The JobHunter plugin needs an update (playbook §4/§5).` Never silently skip the LinkedIn sweep.
- `0 jobs · probe 0` on a page that shows "No matching jobs" is a genuine empty result.

Then dedup: `bash <plugin>/scripts/seen.sh new <ws> < jobs/tmp/linkedin.tsv > jobs/tmp/linkedin-new.tsv` (prints a one-line summary; only new jobs continue).

The same pattern works for other browser-only boards (StepStone, XING…): replace the selector with the board's job-link pattern from the market pack and build the same TSV (prefix ids with the source, e.g. `st:`, `xi:`).

## 5. Job detail — extraction snippet + loading guard (from career-ops)
Open `https://www.linkedin.com/jobs/view/<id>/` and run this snippet (≈ the description's size, typically 500–1,500 tokens, instead of ~17k for `read_page`). It tries the classic description containers first and, on the redesigned page (no description container), takes the text after the "About the job" heading inside `main` up to "About the company"/"Meet the hiring team".
```js
await new Promise(r => setTimeout(r, 1500));
const q = s => document.querySelector(s);
const txt = el => el ? el.innerText.replace(/\n{3,}/g, '\n\n').trim() : '';
const ABOUT = /^(about the job|über die stelle|über den job|stellenbeschreibung|iş hakkında|iş ilanı hakkında|à propos de l’offre d’emploi|à propos de l'offre d'emploi)$/i;
const NEXT = /^(about the company|über das unternehmen|şirket hakkında|meet the hiring team|lernen sie das recruiting-team kennen|set alert for similar jobs|people also viewed)/i;
let desc = txt(q('#job-details, .jobs-description__content, .jobs-box__html-content, .show-more-less-html__markup, .description__text'));
const main = q('main') || document.body;
if (!desc) {   // redesigned page (Oct 2026): plain text after the "About the job" heading
  const h = [...main.querySelectorAll('h1,h2,h3,h4,span,strong,div,p')].find(e => e.children.length === 0 && ABOUT.test(e.innerText.trim()));
  if (h) {
    let box = h.parentElement; while (box && box !== main && box.innerText.trim().length < h.innerText.trim().length + 200) box = box.parentElement;
    const lines = (box || main).innerText.split('\n'); const i = lines.findIndex(l => ABOUT.test(l.trim()));
    const rest = lines.slice(i + 1); const j = rest.findIndex(l => NEXT.test(l.trim()));
    desc = (j >= 0 ? rest.slice(0, j) : rest).join('\n').replace(/\n{3,}/g, '\n\n').trim();
  }
}
const mainText = main.innerText; const cut = mainText.search(/\n(about the job|über die stelle|über den job|iş hakkında)\n/i);
const top = (cut > 0 ? mainText.slice(0, cut) : mainText.slice(0, 700)).replace(/\n{2,}/g, '\n').trim().slice(0, 700);
const btn = [...document.querySelectorAll('button, a')].find(b => /easy apply|einfach bewerben|kolay başvuru|^apply|^bewerben|^başvur/i.test(((b.getAttribute('aria-label') || '') + ' ' + b.innerText).trim()));
const hiring = (mainText.match(/(meet the hiring team|lernen sie das recruiting-team kennen)[:\s]*([^\n]{0,160})/i) || [])[2] || txt(q('.hirer-card__hirer-information, .job-details-people-who-can-help__section--two-pane')).slice(0, 160);
JSON.stringify({ id: (location.href.match(/(?:view\/|currentJobId=)(\d+)/) || [])[1], title: txt(q('h1')) || document.title.split(' | ')[0], top,
  apply: btn ? ((btn.getAttribute('aria-label') || btn.innerText).trim().slice(0, 80)) : 'none',
  closed: /no longer accepting applications|nimmt keine bewerbungen mehr an|artık başvuru kabul etmiyor/i.test(document.body.innerText),
  hiring_team: hiring, description: desc, extraction: desc ? 'ok' : 'EXTRACTION_BROKEN' });
```
**Loading guard — one attempt per job per run:** if `extraction` is `EXTRACTION_BROKEN` (empty description), scroll down once, wait ≤ 5 s and run the snippet again; still empty → `get_page_text` once and take the text between the "About the job" heading and the next section; still unreadable → mark "JD unavailable", try the employer's careers page (aggregator rule), else leave for the user. If this happens on several jobs in one run, add the same "plugin needs an update" line to the digest. Never retry via guest endpoints or workarounds.
From the result capture: full description (verbatim — goes into `job.md` only for shortlisted jobs), seniority/employment type/salary/workplace/applicants from `top`, apply type (`Easy Apply` vs `Apply` → follow the external link once to read the destination host), `closed`, hiring-team name (for the cover-letter salutation).
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
