# Portal playbook: SAP SuccessFactors Recruiting

Very common at large German employers (DAX, Mittelstand groups, public-sector-like companies). Two front-ends exist; read the page to know which one you're on.

## Recognise
- Classic: `career<N>.successfactors.com/career?company=<id>&…` or `…successfactors.eu/career…`
- Career site builder (RMK): company domain like `jobs.<company>.com/job/<city>-<title>/<id>/` with an **Apply now** button that leads to the classic application.

## Start
1. **Apply now** (*Jetzt bewerben*). A **Data Privacy Consent Statement** (*Datenschutzerklärung*) dialog often appears first — reading/accepting it is part of applying; tick and accept (list in summary).
2. Sign-in page: *Sign in* or *Create an account* (email, password, retype, first/last name, country, sometimes "how did you hear about us"), then email verification on some tenants → **user's step**.
   Some tenants offer *Apply with LinkedIn/XING/Indeed* — user's click if they want it.

## Application form (usually ONE long page with sections)
- **Candidate profile**: salutation, names, address, phone, email, country of residence, (date of birth / nationality only if required — follow `profile.yaml` sharing flags; if required and not allowed → ask user).
- **Resume / CV**: *Upload a resume* (*Lebenslauf hochladen*) — attach the tailored CV PDF. Some tenants parse it into profile fields → verify.
- **Cover letter** (*Anschreiben*) attach; **Other attachments** (*Weitere Anlagen*: Zeugnisse, certificates — only shareable ones).
- **Work experience / education** blocks (*Berufserfahrung*, *Ausbildung*) with *Add* buttons and date pickers (prefer typing in the format shown, e.g. `TT.MM.JJJJ` or `MM/DD/YYYY`).
- **Job-specific questions**: salary expectation (*Gehaltsvorstellung*, gross annual), earliest start date (*frühestmöglicher Eintrittstermin*), notice period (*Kündigungsfrist*), work permit (*Arbeitserlaubnis*), language levels, source (*Wie sind Sie auf uns aufmerksam geworden?*), willingness to travel/relocate.
- **Consents**: privacy consent (required), talent pool (*Talentpool*, optional → `preferences.talent_pool_consent`).
- Bottom: **Apply** (*Bewerben*/*Absenden*) — only after summary + yes. *Save draft* exists on most tenants.

## Traps
- Required fields marked `*`; errors appear inline after clicking Apply — scroll up and fix.
- Large single page: read the whole form before filling; fill top-down; re-read before the summary.
- Attachments: file-type/size limits shown next to the field (commonly PDF/DOC, ≤ 5–10 MB).
- Some tenants send a confirmation email that must be clicked (double opt-in) — tell the user.
- Status later visible in the candidate profile (*Meine Bewerbungen*).
