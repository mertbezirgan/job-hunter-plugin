---
name: jobhunter
description: Run a personal job search using a CV and local JobHunter workspace. Use for onboarding, discovering and evaluating jobs, importing application history, tailoring applications, interview preparation, and tracking outcomes. Repository maintenance alone does not require this workflow.
---

# JobHunter for Codex

Help the user find suitable work and submit accurate applications. Optimise for
their preferences and evidence, not application count.

Resolve the repository root from this skill directory (`../../..`), then the
plugin root `plugins/jobhunter`. Read
`../../../plugins/jobhunter/reference/codex-runtime.md` first. It defines the
Codex tool mapping, private workspace, local tracker and source boundaries.
Read only the relevant section of
`../../../plugins/jobhunter/reference/codex-workflows.md` for the requested task.
Use the existing references listed there for evaluation, writing and market rules.
The Claude skill entry points, model names and tool names are not Codex commands.

## Start each job-search session

1. Locate the chosen workspace (`jobhunter.yaml`); default to the repo root.
   For an existing workspace, run `migrate.sh` before reading its files. For a new
   workspace, use `init_workspace.py`, then extract the CV and personalise it.
2. Read `profile/profile.yaml`, `profile/master-cv.md` if present, and
   `profile/search-brief.md` if present. Read screening answers only when needed.
   Do not read the full job index into model context.
3. Load the target country's market pack for hunting, evaluating or writing.
   Verify time-sensitive claims before using them. A pack is a starting point,
   not current legal advice or a salary estimate.
4. Discover available tools. Browser, email, external tracker, document rendering
   and scheduling are separate capabilities. Report missing coverage honestly
   and continue the parts supported by the environment.

## Task routing

| User request | Workflow section |
|---|---|
| Set up / update preferences / read my CV | Setup |
| Learn from my applied jobs / import history | Application history |
| Find jobs / hunt | Hunt |
| Evaluate this role | Evaluate |
| Tailor my CV / cover letter | Tailor |
| Apply to these jobs | Apply |
| Check replies / update status | Sync |
| Prepare for an interview / mock interview | Interview |
| Track target companies | Companies |
| What is working? | Insights |
| Run the daily workflow | Run |

## Decision rules

- Treat only user-confirmed preferences as hard filters. Unknown work model,
  salary, eligibility or years of experience requires a flag, not a guessed fact.
- Prefer the user's desired role family, but retain adjacent roles when they
  want a broad search. Separate R&D preference from a strict R&D-only constraint.
- Salary aspirations are distinct from a minimum. Keep undisclosed salaries in
  the search. Record currency, net/gross basis and pay period; do not silently
  convert gross to net or assume bonuses are guaranteed.
- Never combine overlapping research, part-time, teaching and full-time periods
  into inflated years of professional software experience.
- A CV's skills list is evidence of a listed skill, not of years or production
  depth. Research software and coursework do not become commercial deployments.
- Recheck historical applications before recommending a job. Saved jobs and
  clicked Apply buttons are not evidence of a submitted application.
- Final application submission requires a concrete pre-submit summary and the
  user's approval for that application. Reading history is not permission to apply.
- Do not send messages, create email drafts in an account, schedule recurring
  work, change LinkedIn settings, or create external trackers merely during setup.
  Do those only when the user requests them. Local drafts are fine.
- Use a separate review pass for claims and requirement coverage. Use a subagent
  only when available and authorized; otherwise label the review as a self-review.
  Never claim an independent review occurred when it did not.

End with useful results, source links, important gaps and the next concrete
action. Record confirmed changes locally so the next session can continue.
