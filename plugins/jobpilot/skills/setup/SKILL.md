---
name: setup
description: First-run onboarding (and later updates) for JobPilot. Asks the user which language to talk in, which countries/markets to target and how documents should be written, interviews them about every job preference and personal detail, turns their general CV into a master profile and story bank, connects or creates the Notion tracker, checks Gmail and the browser/LinkedIn session, and schedules the daily automation. Use for "setup", "get started", "update my preferences", "change target country", or when no jobpilot.yaml exists.
---

# JobPilot setup

Read `../../reference/conventions.md` (paths relative to this skill's base directory) and follow it.

Principles: ask in **small batches (3–5 questions)**; use AskUserQuestion when there are clear options, chat for free text; propose smart defaults derived from the CV so the user mostly confirms; summarise each batch before moving on. In update mode (workspace exists) show current values and change only what the user wants — but always offer the market/language questions if they ask to change country.

## Step 0 — Language & workspace
1. First question (in English, short): "Which language should I use with you?" (options: English, Deutsch, Türkçe, Other). Switch to it immediately; store `language.ui`.
2. Workspace: if the current folder has `jobpilot.yaml` → update mode. Else propose `~/JobPilot` (Windows `%USERPROFILE%\JobPilot`) or the current folder. Create the tree from conventions §3; copy templates: `jobpilot.example.yaml`→`jobpilot.yaml`, `profile.example.yaml`→`profile/profile.yaml`, `answers.example.yaml`→`profile/answers.yaml`, `story-bank.example.md`→`profile/story-bank.md`. Write a `.gitignore` excluding everything (the workspace contains personal data).
3. Tell the user: always open this folder in Claude (Code tab → folder, or Cowork) so every command finds the data.

## Step 1 — Market & document language
1. Target countries (multi-select allowed) and current country of residence.
2. For each target country: if `../../reference/markets/<country>.md` exists, load it. Otherwise generate `<workspace>/markets/<country>.md` from `../../reference/markets/_template.md` via research (≤ 12 searches, official sources first), show a summary and let the user correct it.
3. Languages the user speaks + CEFR level + certificates (offer a quick self-assessment guide if they're unsure).
4. Document language policy: "write each application in the posting's language (if your level allows)" vs "always write in <X>"; minimum level to write in a language (default B2); fallback language. Explain the trade-off briefly (e.g. German postings answered in English are often accepted by international companies, but German-language applications score better at Mittelstand employers).

## Step 2 — CV → master profile
1. Ask for the CV (path or drop into chat). Copy to `profile/original-cv.<ext>`. Extract text (Read for PDF; for DOCX use the docx skill or unzip `word/document.xml`).
2. Write `profile/master-cv.md` **verbatim**: every role (exact title, company, location, dates, all bullets), education, skills, certificates, languages, projects, volunteering. Add an empty `## Confirmed additions` section.
3. Enrichment interview (5–8 targeted questions): missing metrics per role ("roughly how many / how much / how often?" — accept "I don't know"), tools used but not listed, best 2–3 achievements, reasons for gaps, projects. Every answer goes to `## Confirmed additions` with `(user-stated YYYY-MM-DD)`.
4. Build 4–8 STAR+R stories in `story-bank.md` from CV + answers, with provenance lines.
5. Optional: LinkedIn profile URL → read it in the browser and list differences vs CV (never edit LinkedIn).
6. Optional: writing samples (old cover letters, LinkedIn About, emails the user wrote) → extract style descriptors only into `profile/writing-style.md` (tone, sentence length, punctuation, preferred verbs, words to avoid — no verbatim sentences, no personal identifiers).
7. Optional documents: certificates, Arbeitszeugnisse/references, transcripts, language certificates, photo → `profile/documents/`; ask which may be uploaded to employers (`documents.attachments_shareable`).

## Step 3 — Preferences interview (fill every field of `profile.yaml`)
Batches (propose defaults from the CV):
1. **Targets**: titles (suggest 3–6), synonyms incl. local-language variants from the market pack vocabulary, skill queries, seniority, years of experience (computed, confirm), stretch tolerance.
2. **Work model & location**: Remote / Hybrid / On-site — which are acceptable and in what order; cities; commute radius; remote scope; relocation (where); travel.
3. **Company**: preferred/avoided industries, company size, blacklist (current employer!), agencies yes/no, deal-breakers, must-haves, employment types (permanent, fixed-term, part-time, working student, internship, contract).
4. **Compensation & availability**: currency, gross/net, period, minimum, expected, how to answer salary questions; notice period; earliest start. Use the market pack's convention (e.g. DE = gross annual EUR).
5. **Eligibility**: the market pack's §1 questions (work authorization wording, visa route, degree recognition, local specifics), driving licence, travel.
6. **Personal data for forms**: name, email, phone, city, address (only if needed), LinkedIn, portfolio, nationality/DOB sharing — confirm they're OK being stored locally and used in applications.
7. **Documents**: CV page limit, photo, signature, tone, address form (Sie/du auto).
8. **Automation**: daily application cap (recommend 10–15; explain LinkedIn account risk), minimum score (default 65), shortlist size, how many top jobs to pre-prepare daily (`pre_tailor_top`, default 3; costs usage), run time (default weekdays 08:00), evening email sync, sources (market pack sources on/off, JobSpy, extra sites, target companies list).
9. **Voluntary questions**: EEO defaults (decline), talent-pool consent, follow companies on LinkedIn.
10. **Answer bank**: fill the obvious entries in `answers.yaml` (years with top 8 tools computed from the CV — confirm).
Show a compact summary table; get an explicit OK.

## Step 4 — Notion tracker
1. ToolSearch `notion`. Missing → ask the user to connect Notion (Claude Settings → Connectors), continue other steps, come back.
2. Ask for their existing tracking page (link or name), search and read it.
   - **Database** → map columns to `../../reference/notion-schema.md` keys; propose adding missing properties; add only after OK. Save mapping in `jobpilot.yaml`.
   - **Plain page** → create database "JobPilot Applications" as a child page with the full schema (labels in English, or translated to `language.ui` if the user prefers — store label mapping). Offer to import existing entries.
3. Status options in pipeline order; create the views if possible.
4. Save ids to `jobpilot.yaml`.

## Step 5 — Gmail
ToolSearch `gmail`. Missing → ask the user to connect Gmail. Test a harmless search (`from:linkedin.com newer_than:7d`, count only). Recommend creating 2–3 LinkedIn job alerts (daily) for the main titles/locations — offer to do it in the browser after the user's OK (this changes LinkedIn settings, so ask explicitly).

## Step 6 — Browser & LinkedIn
Load Claude in Chrome tools in one ToolSearch call (fallback: built-in browser). Open `https://www.linkedin.com/feed/` in a new tab. Not signed in → ask the user to sign in themselves; wait; re-check. Run one test search (first title × first location, past week) → report the count and cache `geoId`. If the market pack has API sources, test one call each (e.g. Arbeitsagentur) and report counts.

## Step 7 — Tooling check
- PDF: render `../../templates/cv.html` to a temp PDF with `bash ../../scripts/render_pdf.sh` (Chrome/Edge must exist).
- Fact check script: run once on the rendered template HTML against `master-cv.md` (expect placeholders/unmatched output — just confirms it runs).
- Optional `uv` for JobSpy: check `uv --version`; if missing, explain and offer the official install command (install only with consent) or keep `sources.jobspy: false`.

## Step 8 — Schedule (full automation)
Ask whether to automate. If yes, create scheduled tasks with the desktop app's scheduled-tasks tool (ToolSearch `scheduled`) — or Cowork scheduled tasks — in this workspace folder:
- "JobPilot daily run" — `schedule.run_cron`, prompt `/jobpilot:run --scheduled`
- "JobPilot email sync" — `schedule.sync_cron`, prompt `/jobpilot:sync --scheduled`
Explain plainly: scheduled runs need the computer awake and the Claude app open; they search, evaluate, prepare documents, update Notion and draft emails — they **never submit applications or send emails**; submitting is a quick attended `/jobpilot:apply` session where the user approves each application.

## Step 9 — Finish
Show the command card (in `language.ui`):
- `/jobpilot:run` — full daily pipeline now (sync → hunt → prepare top jobs → digest)
- `/jobpilot:hunt` — search new jobs only
- Move jobs to **To Apply** in Notion (or tell me the numbers) → `/jobpilot:apply`
- `/jobpilot:evaluate <link>` — deep-dive one job · `/jobpilot:tailor <link>` — CV + letter only
- `/jobpilot:sync` — email → Notion, follow-up drafts
- `/jobpilot:interview <company>` — interview prep & mock interview
- `/jobpilot:insights` — what's working, skill gaps, calibration
- `/jobpilot:setup` — change preferences
Offer to start the first `/jobpilot:run` now.
