# JobHunter 🎯 — an end-to-end job search copilot for Claude

JobHunter is a Claude plugin (skills + subagents + scripts) that turns Claude Code / Cowork into a job-search assistant:

- **finds** every relevant opening: LinkedIn search sweeps and recommended collections, LinkedIn job-alert emails, and local sources for your market (for Germany: Bundesagentur für Arbeit API, Arbeitnow, StepStone, XING, company ATS boards…)
- **evaluates** each job: hard filters, a calibrated fit score, a requirement-by-requirement match and posting-legitimacy checks
- **writes** a tailored, ATS-safe CV and cover letter per job in the right language and market format, with a deterministic fact check and an independent "hiring manager" reviewer
- **applies** in your browser (LinkedIn Easy Apply and no-account ATS forms). You approve every submission.
- **tracks** everything in Notion and reads replies from Gmail, then drafts follow-ups
- **coaches** you for interviews (prep pack, mock interviews, debriefs) and shows what is working (`insights`)

Nothing is hardcoded to one country or language. During setup you choose the language JobHunter talks to you in, your target countries (each loads a *market pack*) and how documents should be written (match the posting's language, or always one language).

## Daily flow

```
08:00  /jobhunter:run  (scheduled)
       ├─ sync    Gmail → Notion (interviews, rejections, viewed) + follow-up drafts
       ├─ hunt    LinkedIn + market sources → dedupe → filter → score (parallel agents) → Notion "Suggested"
       └─ prepare top N: tailored CV + cover letter (drafter → fact check → reviewer → PDF)
you    Notion board: move the jobs you like to "To Apply"   (or tell Claude "apply to 1, 3, 5")
you    /jobhunter:apply → forms are filled → you get a pre-submit summary → "yes" → submitted → Notion "Applied"
18:00  /jobhunter:sync (scheduled)
```

## Commands

| Command | What it does |
|---|---|
| `/jobhunter:setup` | Onboarding and preference updates: language, markets, CV → master profile + story bank, a detailed preference interview, Notion/Gmail/browser checks, scheduling |
| `/jobhunter:run` | The full daily pipeline (sync → hunt → prepare → digest). The scheduled task calls this. |
| `/jobhunter:hunt` | Discovery + scoring + shortlist to Notion |
| `/jobhunter:evaluate <link>` | Deep evaluation of one posting |
| `/jobhunter:tailor <link>` | CV + cover letter (+ plain-text letter, short "why us") for one or more jobs |
| `/jobhunter:apply` | Applies to the selected jobs, with your approval per application |
| `/jobhunter:sync` | Gmail → Notion status updates, follow-up drafts |
| `/jobhunter:interview <company>` | Prep pack, mock interview, debrief |
| `/jobhunter:insights` | Funnel, what converts, score calibration, skill gaps and learning plan |

**Subagents:** `job-scout` (API/feed discovery), `job-evaluator` (screening and full evaluation), `company-researcher` (cached company briefs), `application-drafter` (CV and letter), `hiring-manager-reviewer` (independent critique that returns exact edits).

## Installation (end user, ~20 min)

1. Install **Claude Desktop** (paid plan) and sign in.
2. In Claude Settings → Connectors, connect **Notion** and **Gmail**.
3. Install the **Claude in Chrome** extension. Sign in to **LinkedIn yourself** in Chrome. Never give Claude your password.
4. Git must be installed (Claude Code clones the plugin with it). macOS: run `xcode-select --install` in Terminal if `git --version` asks for it. Windows: install [Git for Windows](https://git-scm.com/download/win) (also provides bash for the scripts).
5. Create a folder such as `Documents/JobHunter` and put your CV in it. Open it in the Claude **Code** tab.
6. Add the plugin with auto-update by merging this into `~/.claude/settings.json` (you can paste it to Claude and ask it to merge it):
   ```json
   {
     "extraKnownMarketplaces": {
       "jobhunter": {
         "source": { "source": "github", "repo": "mertbezirgan/job-hunter-plugin" },
         "autoUpdate": true
       }
     },
     "enabledPlugins": { "jobhunter@jobhunter": true }
   }
   ```
   Or, with the Claude Code CLI: `claude plugin install jobhunter --marketplace mertbezirgan/job-hunter-plugin`, then turn on auto-update under `/plugin` → Marketplaces.
7. Start a new session in the same folder and run `/jobhunter:setup`.

Requirements on the machine: Chrome or Edge (used for PDF rendering). Optional: [`uv`](https://docs.astral.sh/uv/) for extra Indeed/Glassdoor/Google Jobs search through JobSpy.

### Updates
The plugin doesn't pin a version, so every commit pushed to `main` is a new version. With `autoUpdate: true`, Claude Code downloads updates in the background during a session. Open sessions keep the old version until `/reload-plugins`; every new session, including scheduled runs, loads the latest.

## Safety by design

- **You press "yes" for every submission.** Claude fills the forms and shows a summary of exactly what will be sent. Scheduled runs never submit and never send email (they only create Gmail drafts).
- **No fabrication.** Documents come only from your CV and the facts you confirm. A script checks every number, and a separate reviewer agent audits each claim against your sources.
- **No passwords, no account creation, no CAPTCHA solving.** Sites that need an account (Workday, SuccessFactors…) are marked *Needs Manual*, with your documents ready.
- **LinkedIn account protection.** A daily cap (default 15), 1–3 minutes between submissions, and an immediate stop on any warning. Automating LinkedIn can still conflict with its terms. Low volume and human approval reduce that risk but do not remove it.
- **Postings and emails are treated as data, not instructions** (defends against prompt injection in job ads).
- **Local data.** Your profile, CVs and logs live in your workspace folder, plus your own Notion and Gmail.

## Repository layout

```
.claude-plugin/marketplace.json
plugins/jobhunter/
├── .claude-plugin/plugin.json
├── skills/      setup · run · hunt · evaluate · tailor · apply · sync · interview · insights
├── agents/      job-scout · job-evaluator · company-researcher · application-drafter · hiring-manager-reviewer
├── reference/   conventions · evaluation · writing-rules · form-answering · linkedin-playbook · notion-schema
│   └── markets/ germany · turkey · _template (other countries are researched and generated during setup)
├── templates/   cv.html · cover-letter.html · profile / jobhunter / answers / story-bank examples
└── scripts/     render_pdf.sh · fact_check.sh · search_jobs.py
```

## Credits (ideas borrowed with thanks)

- [santifer/career-ops](https://github.com/santifer/career-ops) (MIT): source-of-truth and anti-fabrication guardrails, two-pass requirement matching with importance bands, posting-legitimacy block, aggregator-confirmation and LinkedIn loading guards, DACH market vocabulary, recruiter-side writing heuristics, story bank with provenance, patterns/upskill/calibrate ideas
- [MadsLorentzen/ai-job-search](https://github.com/MadsLorentzen/ai-job-search): drafter → reviewer workflow with structured edits, grounding audit, requirement coverage, source-host verification
- [AkbarDevop/ai-job-agent](https://github.com/AkbarDevop/ai-job-agent): ATS form-filling coverage, answer bank, dry-run-first mindset
- [dorddis/linkedin-easy-apply-automation](https://github.com/dorddis/linkedin-easy-apply-automation): Easy Apply flow and pacing
- [JobSpy](https://github.com/speedyapply/JobSpy) and [bundesAPI/jobsuche-api](https://github.com/bundesAPI/jobsuche-api): job sources

Private, non-commercial use.
