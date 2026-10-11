# Market pack: Germany (DE) — also useful as a base for AT/CH (DACH)

Load this pack when `profile.yaml > market.countries` contains Germany, or a job's location/hiring entity is in Germany. Content is knowledge, not configuration: the user's own answers in `profile.yaml` always win.

## 1. Extra setup questions (ask during /jobpilot:setup)
1. **Right to work in Germany**: EU/EEA/Swiss citizen? Existing German residence title (which; valid until)? Needs a visa → which route is realistic: EU Blue Card (degree + salary threshold — look up the *current year's* thresholds with WebSearch on make-it-in-germany.com; regular vs. shortage-occupation/new-entrant threshold), skilled-worker visa (§18a/§18b AufenthG), job-seeker **Chancenkarte** (Opportunity Card), ICT? Record exact wording to use in forms ("I hold an EU Blue Card valid until …" / "I will require an EU Blue Card; I meet the requirements").
2. **Degree recognition**: is the foreign degree listed as "H+" in anabin / has a ZAB Statement of Comparability? (Matters for Blue Card and regulated professions.)
3. **German level** (CEFR) and certificates (Goethe, telc, TestDaF, ÖSD) with date. **English level** too. Willing to apply to German-only roles? (Filter rule: posting requires "fließend Deutsch"/"verhandlungssicher" (≈C1) and user < B2 → hard filter; "gute Deutschkenntnisse" (≈B2) and user B1 → stretch, flag.)
4. **Location**: current location; target cities (Berlin, München, Hamburg, Frankfurt am Main, Köln, Stuttgart, Düsseldorf…), willingness to relocate inside Germany, remote-from-abroad acceptable? (Many German employers can only employ people resident in Germany — flag "remote (Germany only)".)
5. **Salary**: expected **gross annual** salary in EUR (Bruttojahresgehalt) — min / target. German forms and Anschreiben ask "Gehaltsvorstellung" as one gross annual number or a narrow range.
6. **Start date & notice**: "frühestmöglicher Eintrittstermin", current Kündigungsfrist.
7. **CV style**: photo on CV? (Not required — AGG; common but optional. Default: no photo. If yes, need a professional photo file in `profile/documents/`.) Include date of birth / nationality? (Optional; nationality is useful when work authorization is not obvious. Default: omit DOB, include "Work permit: …" line when relevant.) Signature + place/date at the end of the Lebenslauf? (Traditional, optional; default no.)
8. **Documents to attach**: Arbeitszeugnisse (employer references), degree certificates + transcripts, language certificates. Ask the user to put PDFs in `profile/documents/` with clear names. German employers often expect "vollständige Bewerbungsunterlagen" (Anschreiben + Lebenslauf + Zeugnisse) — merged into one PDF if the form has a single upload (max ~5 MB).
9. **Address form**: Formal "Sie" by default; switch to "du" only if the posting itself uses "du" consistently (common in startups).
10. Gender/diversity questions: Germany usually doesn't ask EEO questions; if asked, use `profile.yaml > eeo`.

## 2. Job sources (in addition to LinkedIn)
| Source | Access | Notes |
|---|---|---|
| **Bundesagentur für Arbeit — Jobsuche** | Public REST (unofficial but stable): `GET https://rest.arbeitsagentur.de/jobboerse/jobsuche-service/pc/v6/jobs` with header `X-API-Key: jobboerse-jobsuche`. Params: `was` (keywords), `wo` (city), `umkreis` (km), `veroeffentlichtseit` (days, 0–100), `angebotsart=1` (employment; 4 = internship/trainee), `arbeitszeit` (`vz` full-time, `tz` part-time, `snw` shift/night/weekend, `mj` mini-job), `befristung` (1 fixed-term, 2 permanent), `zeitarbeit=false` (exclude temp agencies), `page`, `size` (≤100). Response: `ergebnisliste[]` with `stellenangebotsTitel`, `firma`, `referenznummer`, `stellenlokationen[].adresse.ort`, `homeofficemoeglich`, `veroeffentlichungszeitraum.von`, `eintrittszeitraum`. Total in `maxErgebnisse`. Detail page: `https://www.arbeitsagentur.de/jobsuche/jobdetail/<referenznummer>` (public HTML). | Large volume incl. many Mittelstand employers not on LinkedIn. `arbeitszeit=ho` does not work for remote — filter by `homeofficemoeglich` instead. Use `zeitarbeit=false` when `exclude_agencies` is true. |
| **Arbeitnow** | Free JSON feed `https://www.arbeitnow.com/api/job-board-api?page=N` (no search params; ~300/page, newest first; fields `title, company_name, location, remote, url, tags, job_types, created_at (unix), description (HTML)`). Read pages until `created_at` < window start, filter locally. | English-friendly, many startups, visa-sponsorship tags. Please don't abuse; low volume. |
| **StepStone** (`stepstone.de`) | Browser: `https://www.stepstone.de/jobs/<keyword-slug>/in-<city>?radius=30&datePosted=…` or use the search UI | #1 commercial board in DE. Often redirects to company ATS. |
| **XING Jobs** (`xing.com/jobs`) | Browser search | DACH professional network; many Mittelstand roles. |
| **Indeed DE / Glassdoor DE / Google Jobs** | `scripts/search_jobs.py --country germany` (JobSpy) | Optional (needs `uv`). |
| **GermanTechJobs, Berlin Startup Jobs, Wellfound, Make it in Germany job board** | Browser / WebFetch | Tech & English-speaking roles; Make-it-in-Germany lists employers open to international hires. |
| **Company career pages** | Public ATS APIs: Personio `https://<company>.jobs.personio.de/xml` (XML feed) or `.de`; Greenhouse `https://boards-api.greenhouse.io/v1/boards/<board>/jobs?content=true`; Lever `https://api.lever.co/v0/postings/<board>?mode=json`; Ashby `https://api.ashbyhq.com/posting-api/job-board/<board>`; SmartRecruiters `https://api.smartrecruiters.com/v1/companies/<id>/postings`; Join.com / Softgarden / Recruitee pages via WebFetch | For `jobpilot.yaml > sources.target_companies`. |

Kununu (`kununu.com`) = employer reviews — use in evaluation/company research, not as a job source.

## 3. Search vocabulary
- Titles appear in German and English, often with gender tags: "(m/w/d)", "(w/m/d)", "(all genders)", "(m/f/x)". Strip them for dedup; never treat their absence as a fit signal (just a minor AGG-compliance note).
- Always search **both** the English title and German equivalents (e.g. Data Analyst ↔ Datenanalyst/in; Software Engineer ↔ Softwareentwickler/in, Softwareingenieur; Project Manager ↔ Projektleiter/in, Projektmanager/in; Working Student ↔ Werkstudent; Trainee ↔ Trainee; Junior ↔ Berufseinsteiger). Derive variants from the user's titles; confirm the list in setup.
- Work model words: Remote / Homeoffice / mobiles Arbeiten / hybrid / vor Ort / Präsenz.
- Seniority: Werkstudent, Praktikum, Einstieg/Junior, Professional, Senior, Lead/Teamleitung, Head of.
- Employment: Festanstellung/unbefristet (permanent), befristet (fixed-term), Vollzeit/Teilzeit, Zeitarbeit/Arbeitnehmerüberlassung (temp agency — hard filter if `exclude_agencies`), Personalvermittlung ("für unseren Kunden" = recruiter/agency).

## 4. Evaluation notes (DACH specifics, adapted from career-ops `modes/de`)
| Term | Meaning | Impact |
|---|---|---|
| 13. Monatsgehalt / Weihnachtsgeld | extra monthly salary | compare packages as gross × 13 (or ×13.5/14 under Tarif) |
| Probezeit | probation, usually 6 months, 2-week notice | normal; flag only if > 6 months |
| Kündigungsfrist | notice period | plan start dates |
| Urlaub | 25–30 days standard (legal min. 20 on 5-day week) | < 26 days below market for white-collar roles |
| Tarifvertrag (TVöD, IG Metall…) | collective agreement | transparent pay bands, less negotiation room |
| Betriebsrat | works council | stability signal |
| bAV / VWL | company pension / savings contribution | count as benefits |
| Befristet | fixed-term contract | flag to user (can matter for visa/permanent residence plans) |
| Freie Mitarbeit / Freelance | self-employed | not employment — flag (Scheinselbstständigkeit risk, no social insurance) |
| Arbeitnehmerüberlassung | temp agency employment | hard filter if `exclude_agencies` |
Visa signals: posting says "Visa sponsorship"/"relocation support"/"English-speaking team" → positive for non-EU users; "nur mit gültiger Arbeitserlaubnis" (only with valid work permit) → hard filter for users needing sponsorship.

## 5. CV (Lebenslauf) conventions
- Reverse chronological, 1–2 pages, clean tabular look. Dates as `MM/YYYY – MM/YYYY` (German) or `MMM YYYY` (English).
- Header: name, city (+ country if abroad), phone (+49 format if German number), email, LinkedIn. Optional: photo (top right), nationality/work permit line, date of birth.
- Sections (German): Berufserfahrung, Ausbildung / Studium, Kenntnisse (IT-Kenntnisse, Sprachkenntnisse with CEFR levels), Zertifikate, Projekte, Ehrenamt. English: Experience, Education, Skills, Languages, Certifications.
- A short "Profil"/"Kurzprofil" summary is common and helpful for ATS.
- Language skills always with CEFR level + certificate (e.g. "Deutsch – B2 (telc, 2025)").
- Gaps longer than ~3 months are expected to be explained briefly (e.g. "Sprachkurs", "Umzug nach Deutschland") — only with facts from the user.
- Optional ending: "Ort, Datum" + signature (only if `cv.signature: true`).

## 6. Cover letter (Anschreiben) conventions
- One page, DIN 5008-like layout: sender block, recipient (company, contact person, address if known), place + date right-aligned ("Berlin, 11.10.2026" / "Berlin, 11 October 2026"), **subject line in bold** ("Bewerbung als Data Analyst (m/w/d) – Kennziffer 1234" / "Application for Data Analyst – Ref. 1234") — no "Betreff:" word.
- Salutation: "Sehr geehrte Frau Müller," / "Sehr geehrter Herr Müller," if name known; otherwise "Sehr geehrte Damen und Herren," (or "Liebes <Company>-Team," for du-culture startups). English: "Dear Ms Müller," / "Dear Hiring Team,".
- Body (German norms): Einleitung (why this role/company, concrete hook — no "hiermit bewerbe ich mich"), Hauptteil (2 requirement→evidence pairs), Schluss: **Gehaltsvorstellung and Eintrittstermin if the posting asks for them** ("Meine Gehaltsvorstellung liegt bei 62.000 € brutto jährlich. Ich kann zum 01.01.2027 beginnen."), invitation to interview.
- Closing: "Mit freundlichen Grüßen" + name (+ signature image only if provided). English: "Kind regards,".
- List attachments ("Anlagen: Lebenslauf, Zeugnisse") only in German formal letters if attachments are actually sent.

## 7. Common form questions (DE ATS: Personio, SAP SuccessFactors, Softgarden, d.vinci, rexx, Workday, Join, Recruitee, Greenhouse)
- Gehaltsvorstellung (brutto/Jahr) → `compensation`.
- Frühestmöglicher Eintrittstermin / Kündigungsfrist → `availability`.
- Wie sind Sie auf uns aufmerksam geworden? → the actual source (LinkedIn, StepStone, Bundesagentur…).
- Arbeitserlaubnis / Aufenthaltstitel → `eligibility` wording from setup.
- Deutschkenntnisse / Englischkenntnisse → CEFR level.
- Datenschutz consent (required to process the application) → part of the submission; list in pre-submit summary. "Talent pool" consent (keep data for future roles) → optional; follow `preferences.talent_pool_consent` (default ask once in setup).
- Personio forms usually need no account; SuccessFactors/Workday/rexx often need an account → `Needs Manual`.

## 8. Salary research
Sources: StepStone Gehaltsreport, Glassdoor DE, Kununu Gehalt, levels.fyi (tech), Gehalt.de, Tarif tables (public sector TVöD/TV-L). Always gross annual EUR. Note regional differences (München/Frankfurt/Hamburg higher; East lower).
