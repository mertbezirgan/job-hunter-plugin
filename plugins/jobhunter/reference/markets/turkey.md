# Market pack: Türkiye (TR)

## 1. Extra setup questions
- Military service status (men; often asked): "Completed / Exempt / Deferred until YYYY / Not applicable" — exact wording in Turkish: "Tamamlandı / Muaf / Tecilli (YYYY'ye kadar) / Yükümlü değil".
- Driving licence class and year (frequently asked).
- Salary: **net monthly TRY** is the default convention (state net/gross explicitly). Ask min and target.
- Notice period ("ihbar süresi") and earliest start.
- Willingness to work from the office in Istanbul/Ankara/İzmir; commute radius; hybrid days.
- English level (often required for multinationals) + other languages.
- Date of birth / marital status are still sometimes asked — answer only if the user agreed (`personal.share_dob`), never put marital status on the CV.

## 2. Job sources
| Source | Access | Notes |
|---|---|---|
| **Kariyer.net** | Browser search (`https://www.kariyer.net/is-ilanlari/<keyword-slug>?…`); many listings require a Kariyer.net account to apply → `Needs Manual` unless the user is logged in | Largest TR board |
| **LinkedIn** | see linkedin-playbook | Multinationals, tech |
| **Yenibiris, Secretcv** | Browser | Secondary boards |
| **Indeed TR / Glassdoor / Google Jobs** | `scripts/search_jobs.py --country turkey` | Optional |
| **Youthall, Toptalent** | Browser | Graduates & interns |
| **İŞKUR** | Browser (`esube.iskur.gov.tr`) | Public employment agency, mostly blue-collar |
| Company career pages | Public ATS APIs (Greenhouse/Lever/Ashby/SmartRecruiters) | |

## 3. Search vocabulary
Search English and Turkish titles (Data Analyst ↔ Veri Analisti; Software Engineer ↔ Yazılım Mühendisi / Yazılım Geliştirici; Project Manager ↔ Proje Yöneticisi; Intern ↔ Stajyer; Management Trainee ↔ MT). Work model: Uzaktan / Hibrit / Ofisten / Yerinde. Seniority: Stajyer, Yeni mezun, Uzman Yardımcısı, Uzman, Kıdemli, Takım Lideri, Müdür.

## 4. Evaluation notes
SGK registration (formal employment) vs. freelance/"fatura karşılığı" (invoice-based) → flag. Bonus ("ikramiye", often 2–4 extra salaries) and private health insurance ("özel sağlık sigortası"), meal card ("yemek kartı"), transport ("servis") matter for comparing offers. Severance ("kıdem tazminatı") applies after 1 year. Probation ("deneme süresi") max 2 months (4 with collective agreement).

## 5. CV conventions
1–2 pages; photo common but optional (default: no photo); sections Turkish: Deneyim, Eğitim, Yetenekler, Diller, Sertifikalar; dates `MM.YYYY`. Military status line common for men in TR-language CVs (only if user agrees).

## 6. Cover letter conventions
Often optional; short (150–250 words) "Ön yazı". Salutation "Sayın İşe Alım Ekibi," / "Sayın <Ad Soyad>,"; closing "Saygılarımla,".

## 7. Common form questions
Askerlik durumu, ehliyet, maaş beklentisi (net), seyahat engeli, sigara (rarely — skip if optional), referanslar.

## 8. Salary research
Kariyer.net Maaş, Glassdoor TR, Youthall maaş raporları, Levels.fyi (tech); inflation makes data stale fast — prefer data < 6 months old.
