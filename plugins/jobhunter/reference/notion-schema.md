# Notion tracker schema

The Notion database is the **tracker** and the **selection board**: the user moves jobs to `To Apply` in Notion (or says so in chat), and `/jobhunter:apply` picks them up. Default names are English; setup can map them to the user's existing column names or translate them into `language.ui` — the mapping lives in `jobhunter.yaml > notion.properties` / `notion.status_labels`.

## Properties
| Key | Default name | Type | Notes |
|---|---|---|---|
| title | Role | title | job title as posted (gender tag removed) |
| company | Company | rich_text | |
| location | Location | rich_text | city, country |
| work_model | Work Model | select | Remote / Hybrid / On-site / Unknown |
| country | Country | select | for multi-market searches |
| url | Job URL | url | canonical (employer ATS if confirmed, else LinkedIn `/jobs/view/<id>/`) |
| source | Source | select | LinkedIn / LinkedIn Recommended / LinkedIn Alert / Arbeitsagentur / StepStone / XING / Indeed / Arbeitnow / Company Site / Other |
| apply_type | Apply Type | select | Easy Apply / ATS (no account) / ATS (account) / Email |
| language | Job Language | select | de / en / tr / … |
| score | Score | number | 0–100 |
| why | Why | rich_text | 1–2 lines: strongest matches + main gap (in `language.ui`) |
| legitimacy | Legitimacy | select | High confidence / Caution / Suspicious |
| status | Status | select | see below |
| found | Found | date | |
| posted | Posted | rich_text | "3 days ago" or date |
| applied | Applied | date | |
| salary | Salary | rich_text | listed or estimated (marked "est.") |
| folder | Files | rich_text | local path of the application folder |
| response | Last Response | rich_text | "<date> · <class> · summary" |
| next_action | Next Action | rich_text | e.g. "Follow-up draft ready", "Interview 14 Oct 14:00" |
| updated | Updated | date | |
| notes | Notes | rich_text | **user's** — append only, never overwrite |
| source_id | Job ID | rich_text | dedup key (`li:…`, `ba:…`) |

## Status pipeline (order matters: never move backwards automatically)
`Suggested` → `To Apply` → `Prepared` → `Applied` → `Viewed` → `Assessment` → `Interview` → `Offer` → `Hired`
Side states: `Needs Manual` (user action required — reason in Next Action), `Rejected`, `Skipped` (user declined or below threshold), `Closed` (posting closed), `Withdrawn` (user withdrew).

## Existing page migration
If the user already tracks applications in a **plain page**, create the database "JobHunter Applications" **as a child of that page** and offer to import the old entries (company, role, date, result) so dedup and insights include history. If it's already a **database**, map existing columns and add only missing properties after asking. Never delete or rewrite the user's existing content.

## Views (create if the Notion tool supports it; otherwise tell the user how in one line)
- **Board** grouped by Status (main selection UI)
- **Today's suggestions**: Status = Suggested, sorted by Score desc
- **Active pipeline**: Status in Applied…Offer
