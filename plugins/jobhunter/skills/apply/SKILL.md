---
name: apply
description: Apply to the jobs the user selected (Notion status "To Apply"/"Prepared"/"Needs Manual", or numbers/links given in chat) - ensures tailored documents exist, fills LinkedIn Easy Apply and no-account ATS forms, then handles portals that need an account (Workday, SuccessFactors, Taleo, iCIMS, rexx…) in assisted mode where the user only creates the account or signs in and Claude fills the rest. Shows a pre-submit summary and submits only after the user's explicit yes for that application, then updates Notion and logs everything. Always attended. Use for "apply", "send my applications", "apply to 1, 3 and 5", "do the Workday ones".
---

# JobHunter apply

Read (relative to this skill's base directory) `../../reference/conventions.md`, `../../reference/linkedin-playbook.md`, `../../reference/form-answering.md`, `../../reference/notion-schema.md`, `../../reference/portals/_assisted-mode.md` and the market pack(s). Load profile files (incl. `profile/portal-accounts.yaml`, create it from `../../templates/portal-accounts.example.yaml` if missing) and `jobhunter.yaml`.

**Always attended.** Invoked with `--scheduled` → only run Phase 1 for `To Apply` rows (Status → `Prepared`), then stop.

## Phase 0 — Queue
- Targets: Notion rows with Status `To Apply` or `Prepared` (ask whether `Prepared` ones from earlier days should be included), `Needs Manual` rows whose Next Action says "Portal account step pending", plus links/numbers from the chat.
- Today's submissions = Notion rows with Applied = today. Remaining = `limits.daily_applications` − that. Over the limit → highest scores first; the rest wait (tell the user).
- For each target know its route: Easy Apply / ATS without account / **portal with account** / unknown (Apply Type column, or open the posting's Apply link once to see the host — see `linkedin-playbook.md` §7).
- Show the queue in two groups — **A: automatic** (Easy Apply, no-account ATS) and **B: together with you** (account portals, with portal name and whether an account already exists in `portal-accounts.yaml`) — and an estimate ("B needs you for ~1–2 min each"). Then start.

## Phase 1 — Prepare (no form filling yet)
Run `../tailor/SKILL.md` for every job without reviewed PDFs (parallel agents). Then offer: "Documents are ready — want to look through them first, or shall I start the applications?" (links to the PDFs).

## Phase 2 — Group A: one application at a time (browser, main thread)
For each job:
1. Open the apply route (Job URL; for LinkedIn jobs the posting page). Closed → Status `Closed`, next.
2. Classify (playbook §6/§7). Turns out to need an account / sign-in → move it to group B. CAPTCHA, unusual data requests (ID, bank, payment) → Status `Needs Manual` (reason in Next Action), leave the tab open, next.
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
   - **yes** → click Submit; confirm the success message/"Applied" state; record the confirmation text.
   - **change …** → edit fields, show the summary again.
   - **skip** → close without submitting (LinkedIn: Discard), Status stays `Prepared`.
   - New answers → after confirming, append to `answers.yaml` (with `source: user-stated <date>`).
   A "yes" covers only this application.
6. After a submission: Notion Status `Applied`, Applied = today, Updated, Next Action "Follow up on <date + 10 days>"; `log.md` in the folder (timestamp, URL, apply route, fields + answers, files, confirmation text); index status `applied` (`printf "<id>	applied
" | bash <plugin>/scripts/seen.sh status <ws>`).
7. Wait 60–180 s (random) before the next **submit click** on LinkedIn; you may open and fill the next form meanwhile.
8. Stop signals (playbook §8) → stop LinkedIn work, continue with group B if the user wants.

## Phase 3 — Group B: assisted mode (portals that need an account)
Ask once: "Now N applications on company portals. For each one I'll open the page, you create the account or sign in (about a minute), type **done**, and I fill in everything else. Start now? (yes / later)". `later` → all group B rows: Status `Needs Manual`, Next Action "Portal account step pending (<Portal>) — run /jobhunter:apply".
For each job follow `../../reference/portals/_assisted-mode.md` exactly, using the portal playbook for its host:
- Workday → `../../reference/portals/workday.md`
- SAP SuccessFactors → `../../reference/portals/successfactors.md`
- Taleo / Oracle, iCIMS, rexx, d.vinci, Softgarden, SmartRecruiters, board-side applies → `../../reference/portals/other-portals.md`
Key points: the user does every account/sign-in/verification/CAPTCHA step and types **done**; Claude never types passwords or clicks SSO consent; Claude fills all application pages, verifies any résumé autofill against `master-cv.md`, shows the same pre-submit summary (plus portal, tenant, account email, e-signatures/consents included) and submits only after **yes**; then records Notion, `log.md`, `portal-accounts.yaml` (no passwords) and new answers. If the portal requires an email confirmation after submitting (double opt-in), tell the user to click it.
If something new about a portal's behaviour was learned (a trap, a field quirk), append a short dated note to `notes` of that tenant in `portal-accounts.yaml` so the next run benefits.

## Phase 4 — Report
```
✅ Submitted 6 (4 automatic · 2 portals) · ⏭ Skipped 1 · ⏸ Later 1 · ✋ Needs you 1 · 🚫 Closed 1 · Remaining today: 7
Later (portal account step pending): Senior BI Analyst — BigCorp (Workday) → run /jobhunter:apply when you have 2 minutes
Needs you: Data Engineer — Foo AG (CAPTCHA on page 2) → tab open, documents in applications/…/
📧 Confirm by email: Bar GmbH (rexx) — click "Bewerbung bestätigen" in your inbox
New saved answers: 2 · New portal accounts: 1
```
Offer `/jobhunter:sync` later to catch confirmation emails.
