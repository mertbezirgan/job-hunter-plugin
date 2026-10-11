---
name: interview
description: Interview preparation for a specific company/role - company intel, round-by-round plan by audience (recruiter, hiring manager, technical/case, panel), likely questions mapped to the user's STAR+R story bank, questions to ask, logistics; plus interactive mock interviews with structured feedback and post-interview debriefs. Use for "prepare me for the interview at X", "mock interview", "practice", "debrief", "Vorstellungsgespräch".
---

# JobHunter interview

Read `../../reference/conventions.md` (relative to this skill's base directory) and the market pack for the job's country. Inputs: company (and role) or a Notion row; the application folder (`job.md`, `evaluation.md`, the CV and letter actually sent), `profile/story-bank.md`, `master-cv.md`, `interviews/<company-slug>.md` (if a stub with invite details exists).

Modes (ask if unclear): **prep** (default), **practice**, **debrief**.

## prep
1. Research: `jobhunter:company-researcher` with purpose `interview` (≤ 12 searches; refresh cache). In parallel, read the job folder.
2. Write `interviews/<company-slug>.md`:
   - **Logistics**: date/time/timezone, format, interviewers (names/roles if known from the invite — look up their public LinkedIn headline only if the user agrees), language of the interview, what to bring (ID, certificates — common in DE), travel.
   - **Process overview & audience map**: expected rounds and who's in them (recruiter screen → hiring manager → technical/case → team/panel → final), what each audience is buying.
   - **Per audience: 6–10 likely questions** (from the JD's critical/high requirements, evaluation gaps, market norms — e.g. DE: "Warum möchten Sie wechseln?", salary expectation, notice period; motivation for Germany/relocation if applicable).
   - **Story mapping**: each question → best story from `story-bank.md` (or "story needed" → ask the user to tell it now, write it with provenance).
   - **Gap handling**: for each critical/high gap — honest answer + bridge + learning plan.
   - **Technical/case checklist**: topics to refresh with 1-line pointers.
   - **Questions to ask** (5–8, specific to the company brief; tailored per audience).
   - **Salary & negotiation**: market data (from evaluation D / market pack §8), the user's range, how to phrase it in the interview language.
   - **Red flags to probe** (from legitimacy notes and reviews).
3. Show a one-screen summary; offer practice.

## practice (interactive mock interview)
- Ask: round type (recruiter / hiring manager / technical / case / behavioural panel), language (offer the interview's language — practising German answers is valuable even if weaker), number of questions (default 6), difficulty.
- One question at a time; wait for the answer. After each answer give structured feedback: what worked, what was missing (STAR completeness, concrete result, relevance to the JD), a stronger version **using only the user's real facts**, language corrections if practising in a non-native language, and a 1–5 rating.
- End with a session summary: strengths, top 3 fixes, stories to strengthen. Append to `interviews/<company-slug>.md` (questions, ratings, fixes). New true facts → `master-cv.md` Confirmed additions / story bank with provenance.

## debrief (after a real interview)
Ask: questions asked, how answers went, interviewer reactions, next steps/timeline, any salary discussion. Write to the interview file; update Notion (Status stays `Interview` or moves per news; Next Action e.g. "Thank-you email draft", "Expect feedback by <date>"); create a short thank-you **Gmail draft** if the market/context fits (never send). Record weak answers as practice items.
