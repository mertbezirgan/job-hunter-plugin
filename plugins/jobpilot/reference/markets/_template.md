# Market pack template — used by /jobpilot:setup to generate `<workspace>/markets/<country>.md`

When the user targets a country without a shipped pack in `reference/markets/`, setup researches it (WebSearch/WebFetch, ≤ 12 queries; prefer official government and major job-board sources) and writes a pack with exactly these sections. Mark anything unverified as "(unverified)". Show the user a summary and let them correct it.

## 1. Extra setup questions
Work authorization routes and the exact wording to use in forms; local-language level expectations; salary convention (gross/net, monthly/annual, currency); notice-period norms; CV personal-data norms (photo, DOB, nationality, marital status — note anti-discrimination law); mandatory-service or other locally common questions; documents employers expect (references, transcripts, certificates).

## 2. Job sources
Top 3–6 job boards + any public/government job APIs (endpoint, auth header, parameters, response fields — test one call), local professional networks, startup boards. Whether each is reachable via API, WebFetch or browser only.

## 3. Search vocabulary
Local-language equivalents for the user's target titles, seniority words, work-model words (remote/hybrid/on-site), employment-type words, agency/temp-work words, gender-tag conventions in titles.

## 4. Evaluation notes
Local employment terms that change the value of an offer (bonus salaries, probation, statutory leave, collective agreements, contractor vs employee wording), visa-sponsorship signals, red flags typical for the market.

## 5. CV conventions
Length, section names in the local language, date format, photo/personal data norms, language-skill notation.

## 6. Cover letter conventions
Expected or optional? Length, layout (sender/recipient blocks, subject line), salutations and closings, whether salary expectation/start date go in the letter, formal vs informal address.

## 7. Common form questions
Typical questions on local ATS forms and how to answer them from `profile.yaml`; which local ATS systems usually require an account.

## 8. Salary research
Where to find credible salary data; regional differences.
