---
name: tailor
description: Produce a job-specific, ATS-safe CV and cover letter (plus plain-text letter and short "why us" answer) for one or more jobs, using a drafter agent, a deterministic fact check, and an independent hiring-manager reviewer agent, then render and verify the PDFs. Use for "prepare my CV for this job", "write a cover letter", "Anschreiben", "tailor", or as a step of run/apply.
---

# JobHunter tailor

Read `../../reference/conventions.md` and `../../reference/writing-rules.md` (relative to this skill's base directory) and the market pack for each job's country.

Input: Notion rows, job links, application folders, or pasted JD text. Multiple jobs → process in parallel (max `limits.parallel_agents` agents at a time).

## Per job
1. **Ensure inputs**: `job.md` (fetch if missing, as in `/jobhunter:evaluate` step 1) and `evaluation.md` (run `job-evaluator` full mode if missing). If the evaluation verdict is Skip or legitimacy is Suspicious, tell the user and stop for that job unless they confirm.
2. **Resolve document language** (conventions §1): posting language vs user level vs policy. Note the decision in `review.md`.
3. **Company brief**: `companies/<slug>.md` fresh? else `jobhunter:company-researcher` (purpose `letter`).
4. **Draft**: `jobhunter:application-drafter` with all absolute paths, the resolved language and `language.ui`. (Fallback without agents: follow the drafter's steps inline.)
5. **Review**: extract plain text of `cv.html` and `cover-letter.html` (strip tags) and pass it inline with the JD text to `jobhunter:hiring-manager-reviewer` (fresh context).
6. **Revise**: apply Part A edits with Edit (skip any that would need invented content); address Part B notes; re-run `../../scripts/fact_check.sh` on both files (`--sources master-cv.md profile.yaml answers.yaml --context job.md`). Must end with OK (or only "from posting" numbers that refer to the job). Save reviewer verdict + notes + fact-check output in `review.md`.
7. **Render**: in the folder run `bash <skill base>/../../scripts/render_pdf.sh cv.html cv.pdf` and the same for `cover-letter.html` → `cover-letter.pdf`.
8. **Verify PDFs**: Read each PDF: page count within limits (letter = 1 page), nothing cut off, no `{{`, selectable text, correct language. Over the limit → tighten (shorter summary, fewer bullets on old roles) and re-render.
9. **Upload names**: copy to `<First>_<Last>_CV_<Company>.pdf` and `<First>_<Last>_Cover_Letter_<Company>.pdf` (ASCII, no spaces; German letters could use `Anschreiben` in the name when the document language is German). If the market expects one combined file (e.g. DE "Bewerbungsunterlagen") and shareable documents exist, also build `<First>_<Last>_Application_<Company>.pdf` = letter + CV + shareable certificates (merge with the pdf skill or `qpdf`/`pdfunite` if available; otherwise skip and note).
10. **Notion**: Files = folder path, Updated; Status → `Prepared` if it was `To Apply`; Next Action "Documents ready".

## Attended hand-off
Show per job: angle (1 line), score, keywords covered/missing, honest bridges used, reviewer verdict, file links. Ask if they want changes; apply edits to the HTML, re-check facts, re-render. Any new fact the user tells you → `master-cv.md` "Confirmed additions" in the same turn.
