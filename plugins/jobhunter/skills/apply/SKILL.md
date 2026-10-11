---
name: apply
description: Apply to the jobs the user selected (Notion status "To Apply"/"Prepared", or numbers/links given in chat) - ensures tailored documents exist, fills LinkedIn Easy Apply or the employer's ATS form in the browser, shows a pre-submit summary and submits only after the user's explicit yes for that application, then updates Notion and logs everything. Always attended. Use for "apply", "send my applications", "apply to 1, 3 and 5".
---

# JobHunter apply

Read (relative to this skill's base directory) `../../reference/conventions.md`, `../../reference/linkedin-playbook.md`, `../../reference/form-answering.md`, `../../reference/notion-schema.md` and the market pack(s). Load profile files and `jobhunter.yaml`.

**Always attended.** Invoked with `--scheduled` → only run Phase 1 for `To Apply` rows (Status → `Prepared`), then stop.

## Phase 0 — Queue
- Targets: Notion rows with Status `To Apply` or `Prepared` (ask whether `Prepared` ones from earlier days should be included), plus links/numbers from the chat.
- Today's submissions = Notion rows with Applied = today. Remaining = `limits.daily_applications` − that. Over the limit → highest scores first; the rest wait (tell the user).
- Show the queue (# · score · role — company · apply type · docs ready?) and start.

## Phase 1 — Prepare (no form filling yet)
Run `../tailor/SKILL.md` for every job without reviewed PDFs (parallel agents). Then offer: "Documents are ready — want to look through them first, or shall I start the applications?" (links to the PDFs).

## Phase 2 — One application at a time (browser, main thread)
For each job:
1. Open the apply route (Job URL; for LinkedIn jobs the posting page). Closed → Status `Closed`, next.
2. Classify (playbook §6/§7). Account required / CAPTCHA / login wall / unusual data requests → Status `Needs Manual` (reason in Next Action), leave the tab open, next.
3. Fill every step per `form-answering.md`: contact data, tailored CV upload, cover letter upload/paste, questions, `why-short.txt` for motivation boxes, required privacy consent. Unknown required answers → collect, don't guess.
4. On the final review step, **stop** and show the pre-submit summary (in `language.ui`):
```
📨 3/8 · Data Analyst — Acme GmbH (Easy Apply) · score 86 · document language: German
CV: Max_Mustermann_CV_Acme.pdf · Cover letter: uploaded
Filled: email max@…, phone +49…, SQL experience: 3 years, hybrid: yes, salary: 62,000 EUR gross/yr, start: 01.01.2027, work permit: EU Blue Card required (eligible)
Consents: data-processing consent (required) ✔ · talent pool ✖
❓ Need your answer: "Do you have experience with Looker?"
Submit this application? (yes / change: … / skip)
```
5. Wait for the user's reply:
   - **yes** → click Submit; confirm the success message/"Applied" state; screenshot not needed — record the confirmation text.
   - **change …** → edit fields, show the summary again.
   - **skip** → close without submitting (LinkedIn: Discard), Status stays `Prepared`.
   - New answers → after confirming, append to `answers.yaml` (with `source: user-stated <date>`).
   A "yes" covers only this application.
6. After a submission: Notion Status `Applied`, Applied = today, Updated, Next Action "Follow up on <date + 10 days>"; `log.md` in the folder (timestamp, URL, apply route, fields + answers, files, confirmation text); `seen.jsonl` status `applied`.
7. Wait 60–180 s (random) before the next **submit click**; you may open and fill the next form meanwhile.
8. Stop signals (playbook §8) → stop everything, report.

## Phase 3 — Report
```
✅ Submitted 6 · ⏭ Skipped 1 · ✋ Needs you 2 · 🚫 Closed 1 · Remaining today: 9
Needs you:
 - Senior BI Analyst — BigCorp (Workday, account required) → files: applications/…/ · tab open
New saved answers: 2
```
Offer `/jobhunter:sync` later to catch confirmation emails.
