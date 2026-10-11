# Assisted mode — applications on portals that need an account

Used by `/jobhunter:apply` for jobs whose apply route is a candidate portal that requires an account or sign-in (Workday, SAP SuccessFactors, Taleo, iCIMS, rexx/d.vinci/Softgarden when they ask for one, …). **Always attended.**

## Division of work (fixed — these are Claude's safety rules, not settings)
| The user does | Claude does |
|---|---|
| Creates the account or signs in (email, password, "Continue with Google/LinkedIn/XING" consent) | Opens the right page, says exactly what to do, waits |
| Clicks email verification links/codes for the **account** | Detects when sign-in is complete |
| Answers security questions, CAPTCHAs, 2FA | Fills every application page afterwards |
| Says **yes** to the final summary | Uploads documents, answers questions, submits after yes, records everything |

Claude never types a password, never fills a "create account" form's password fields, never clicks an OAuth/SSO consent, never solves a CAPTCHA, never reads or stores passwords. Passwords live only in the user's password manager (macOS Passwords / iCloud Keychain, 1Password, Chrome's manager).

## Portal account registry — `profile/portal-accounts.yaml`
One entry per portal **tenant** (each company's Workday is a separate account):
```yaml
- company: Siemens
  portal: workday
  host: siemens.wd3.myworkdayjobs.com
  account_email: name@example.com
  created: 2026-10-12
  last_used: 2026-10-12
  notes: "Use 'Use my last application' — profile already complete"
```
Never store passwords, security answers or codes here. Update `last_used` after each use.

## Procedure per job
1. **Prepare first**: tailored CV/letter PDFs must exist (tailor workflow). Never start a portal session without them.
2. **Open & identify**: open the apply link (from the posting's "Apply" button or the stored Job URL). Identify the portal from the host (see `reference/portals/*.md`); read that playbook. Unknown portal → use the generic rules below and be extra careful.
3. **Check registry**:
   - Known tenant → "You already have an account on <host> (<account_email>). If Chrome isn't signed in, please sign in in the open tab and type **done**." If the page already shows the signed-in candidate home/application form, skip the wait.
   - New tenant → "This job uses <Company>'s <Portal> portal, which needs an account. In the open tab please: click *Create Account*, use **<account_email>**, let your password manager generate and save the password, accept the terms, and confirm the verification email if one arrives. Then type **done** — or **skip** / **later**."
4. **Wait** for the user's reply. `skip` → Status `Skipped` (Next Action "User skipped portal"). `later` → Status `Needs Manual`, Next Action "Portal account step pending (<Portal>) — run /jobhunter:apply". Never poll the page in a loop while waiting; read it once after "done".
5. **Verify**: after "done", read the page. Signed in and inside the application flow (or the job page with an Apply button now available) → continue. Still on login/verification → tell the user what the page shows and wait again. Add/refresh the registry entry.
6. **Fill** page by page following the portal playbook and `reference/form-answering.md`:
   - Prefer the portal's "Apply manually" path; use "Autofill with resume"/"Import from LinkedIn" only if the playbook says it's reliable, and then **verify every parsed field** against `master-cv.md` (titles, companies, dates, education, languages). Fix or delete wrong/duplicate entries.
   - Upload the tailored CV (and letter if there's a slot). Attach shareable certificates only where the form asks for them.
   - Read each page fully before acting (`read_page`/`find`; forms may be inside iframes — iCIMS especially). After each "Next/Save and Continue", read again and fix any validation errors shown.
   - Keep a running list of everything filled for the summary. Unknown required questions → collect, don't guess.
   - Sessions time out (often 15–30 min idle): if bounced to sign-in, ask the user to sign in again; most portals keep the draft.
7. **Review page → summary**: show the standard pre-submit summary (apply skill format) plus: portal + tenant, account email, uploaded files, every page's key answers, consents/e-signatures that the submission includes (typed-name e-signatures count as part of the submission and are covered by the user's yes for this application only).
8. **yes** → Submit; confirm the "Application submitted"/"Vielen Dank" page; record confirmation text. Some German portals require an **email confirmation after submission** (double opt-in: "Bitte bestätigen Sie Ihre Bewerbung") — tell the user to click that link in their inbox (sync will remind them).
9. **Record**: Notion (Status `Applied`, Applied date, Apply Type `ATS (account)`, Next Action follow-up date), `log.md` (portal, tenant, pages, answers, files, confirmation), `portal-accounts.yaml` (`last_used`), `answers.yaml` for any new confirmed answers.

## Generic rules for unknown portals
- If any page asks for national ID/passport numbers, tax/social-security numbers, bank details, payment, or background-check consent with ID upload → stop, flag, `Needs Manual`.
- Look-alike or unexpected hosts (not the employer's domain or a known ATS) → stop, legitimacy red flag.
- Don't create "job alerts"/talent-community subscriptions unless `preferences.talent_pool_consent: yes`.
- Never change the account's password, email, or communication settings.

## Time-saving
- Batch: do all portal jobs at the end of an apply session, one after another, so the user can stay nearby for the 1-minute account steps.
- Same tenant again → usually signed in already + "Use my last application"/saved profile → only verify and answer job-specific questions.
