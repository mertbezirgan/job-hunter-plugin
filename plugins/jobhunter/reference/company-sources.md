# Company watchlist — how career pages are found, recorded and checked

The user keeps a list of companies they want to work for in `<ws>/profile/companies.yaml`. Every hunt checks each active company's own careers page for new openings, using the access method recorded once during research — **never re-discover a careers page during a hunt** (that is what the record is for).

## Registry entry (`profile/companies.yaml`)
```yaml
- name: Allianz                      # as the user calls it (also used for dedup with LinkedIn listings)
  website: https://www.allianz.de
  careers_url: https://careers.allianz.com/en/jobs.html      # the page a human would open
  ats: workday                       # see table below; "custom" if none
  method: api                        # api | rss | webfetch | browser  (cheapest that works)
  board: https://allianz.wd3.myworkdayjobs.com/Allianz       # what scripts/company_jobs.pl needs (api/rss)
  search: ""                         # optional keyword pre-filter for big boards (workday/smartrecruiters), comma-separated
  list_hint: ""                      # webfetch/browser: how to find the job list on careers_url (selector, filter URL, paging)
  notes: "German jobs also on careers.allianz.de; Workday tenant 'allianz'"
  status: active                     # active | paused | needs-research | removed
  added: 2026-10-25
  verified: 2026-10-25               # last time the method was confirmed to return jobs
  last_checked: null
  last_result: ""                    # e.g. "312 open · 4 match" or "ERROR no response"
  failures: 0                        # consecutive failed checks
```
Removing a company sets `status: removed` (history and dedup stay intact); only delete the entry if the user explicitly asks for deletion.

## Access methods, cheapest first (research picks the first that works)
| method | when | how a hunt reads it | cost |
|---|---|---|---|
| `api` | known ATS with a public job API (table below) | one `perl <plugin>/scripts/company_jobs.pl … --source "<ats>\|<board>\|<name>"` call for **all** api/rss companies together; only matching jobs come back as TSV | ~0 tokens per company + ~25 per matching job |
| `rss` | the careers site exposes an RSS/Atom job feed | same script with `rss\|<feed url>` | same |
| `webfetch` | server-rendered job list (HTML contains the jobs) | `job-scout` agent: WebFetch `careers_url` (+ `list_hint`) with a prompt that returns only matching jobs as TSV | ~1–3k tokens per company |
| `browser` | JS-rendered list, bot protection (Cloudflare "Just a moment…"), or anything else | main thread, after the LinkedIn sweep: open `careers_url`, apply `list_hint`, extract job links with a small `javascript_tool` snippet (same TSV shape as playbook §4) | ~1–3k tokens per company |

## ATS detection (from the careers page URL, the "Apply" links, or embedded scripts)
| ats | recognise by | `board` value for the script | notes |
|---|---|---|---|
| greenhouse | `boards.greenhouse.io/<b>`, `job-boards.greenhouse.io/<b>`, `?gh_jid=`, embed `boards-api.greenhouse.io/v1/boards/<b>` | `<b>` | |
| lever | `jobs.lever.co/<b>` (`jobs.eu.lever.co` → `eu:<b>`) | `<b>` or `eu:<b>` | |
| ashby | `jobs.ashbyhq.com/<b>` | `<b>` | |
| smartrecruiters | `jobs.smartrecruiters.com/<b>/…`, `careers.smartrecruiters.com/<b>` | `<b>` (case-sensitive), or `<b>@<cc>` to keep one country (e.g. `BoschGroup@de`) | big boards: set `search` with **single specific words** (multi-word terms match either word) |
| workday | `<tenant>.wd<N>.myworkdayjobs.com/<site>` (optionally `/en-US/<site>`) | full career-site URL `https://<tenant>.wd<N>.myworkdayjobs.com/<site>` | always set `search` for big employers |
| personio | `<b>.jobs.personio.de` / `.com` | `<b>` or the full host | |
| recruitee | `<b>.recruitee.com` | `<b>` | |
| rss | any feed URL that returns `<item>`s (some Teamtailor, SuccessFactors career sites, Join) | the feed URL | test it — many guesses 404 or are bot-protected |
| successfactors, softgarden, d.vinci, rexx, avature, phenom, eightfold, oracle, icims, taleo, join, teamtailor, workable, custom | various | — | use `rss` if a working feed exists, else `webfetch`, else `browser` |

## Filters (keep company checks cheap and relevant)
`jobhunter.yaml > companies` holds `title_re` and `loc_re` (case-insensitive Perl regexes), built during setup from `targets.titles`, synonyms, skill keywords and local-language variants, and from `targets.locations` + remote scope (e.g. `title_re: 'analyst|analytics|data|daten|business intelligence|\bbi\b'` — use single quotes in YAML, `loc_re: "berlin|münchen|munich|hamburg|germany|deutschland|remote.*(germany|europe|emea|dach)"`). Jobs with an unknown location are kept (the evaluator decides). Update the regexes whenever the user changes target titles or locations.

## Health
- A check that errors or returns 0 open jobs for a company that normally has jobs → `failures += 1`, keep `last_result`. At `failures >= 2` set `status: needs-research`; the next run (attended or scheduled) re-researches that company with the `career-page-researcher` agent and updates the entry (research is read-only, so it's allowed unattended).
- A successful check resets `failures` to 0 and updates `last_checked`/`last_result` (and `verified`).
- Re-verify every entry at least every 90 days (`verified` older than 90 days → light re-check of the method during the next run).
