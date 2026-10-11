# Portal playbooks: Taleo, iCIMS, rexx, d.vinci, Softgarden, SmartRecruiters, others

Shapes vary by tenant; read every page. Account steps are always the user's (see `_assisted-mode.md`).

## Oracle Taleo
- Host: `<company>.taleo.net/careersection/…` (newer Oracle Recruiting Cloud: `…oraclecloud.com/hcmUI/CandidateExperience/…`).
- Flow: **Apply Online** → privacy/legal agreement (accept, list in summary) → *Login* or *New User* (username, password, email, **security questions** → all user's step) → steps shown as tabs: *General Profile* → *Resume upload* (optional parsing — verify) → *Personal Information* → *Work Experience* → *Education* → *Questionnaire* → *Diversity* (voluntary) → **eSignature** (typed full name/date — part of submission, covered by the user's yes) → *Review and Submit*.
- Traps: "Save and Continue" per step; session timeouts; some fields duplicated between steps — keep them consistent. Oracle Recruiting Cloud: email + one-time code login (user enters the code).

## iCIMS
- Host: `careers-<company>.icims.com/jobs/<id>/<title>/job` (often embedded in the company site).
- **The form lives in an iframe** — use `read_page`/`find` and make sure actions target elements inside it.
- Flow: **Apply for this job online** → email entry → new candidates create a profile with password (user's step) → *Resume upload* (parses — verify) → *Contact information* → *Profile/experience* → *Job questions* → *EEO* (voluntary) → *e-signature* → **Submit**.

## rexx systems (common in DE)
- Host: `<company>.rexx-recruitment.com/…` or `…/bewerberportal/…`; labels in German.
- Two variants: **guest application form** (*Online-Bewerbung*, no account — treat like a normal no-account ATS) or **applicant account** (*Bewerberkonto*/*Registrieren* — user's step).
- Typical fields: *Anrede, Titel, Vorname, Nachname, Straße, PLZ, Ort, Land, Telefon, E-Mail, Geburtsdatum (optional?), Gehaltsvorstellung, frühestmöglicher Eintrittstermin, Kündigungsfrist, Wie sind Sie auf uns aufmerksam geworden?*, uploads *Anschreiben / Lebenslauf / Zeugnisse* (often separate slots), *Datenschutzerklärung* checkbox.
- After submit: frequently a **double opt-in email** ("Bitte bestätigen Sie Ihre Bewerbung") — the application is not valid until the user clicks it.

## d.vinci (common in DE, public sector & hospitals)
- Host: `<company>.dvinci-hr.com/jobs/<id>/apply` or `…/de/jobs/<id>/apply`.
- Usually a **single form without account**; some tenants offer an applicant portal login.
- Fields similar to rexx; uploads may be one combined PDF ("Bewerbungsunterlagen in einer PDF-Datei") → use the combined application PDF if the tailor step built one.
- Double opt-in email is common.

## Softgarden (common in DE)
- Host: `<company>.softgarden.io/job/<id>` or `…/de/vacancies/<id>`.
- Options: *Mit LinkedIn/XING bewerben* (user's click), or the form; account is optional on most tenants.
- Form: contact data, CV upload (may parse), cover letter text/upload, questions, privacy consent. Sometimes double opt-in.

## SmartRecruiters
- Host: `jobs.smartrecruiters.com/<Company>/<id>-<title>`.
- **I'm interested** → one-page form (no account) or *Continue with LinkedIn/Indeed* (user's click). Fields: contact data, CV upload (parses — verify experience/education), message to hiring team (use `cover-letter.txt`), questions, privacy consent.

## Personio, Greenhouse, Lever, Ashby, Workable, Join, Recruitee, Teamtailor
No account normally — handled in the normal apply flow, not assisted mode. If one unexpectedly demands an account, switch to assisted mode.

## Kariyer.net (TR) / StepStone "Ich bin interessiert" / XING apply
Board-side applications that need the user's board account → assisted mode (user signs in; Claude fills the board's form).
