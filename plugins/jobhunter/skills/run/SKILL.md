---
name: run
description: JobHunter daily pipeline orchestrator - syncs application emails into Notion, hunts and evaluates new jobs across all sources, prepares tailored CVs and cover letters for the top suggestions, and sends a digest. Designed for the daily scheduled task (--scheduled) but can be run manually. Never submits applications. Use for "daily run", "run the pipeline", "do today's job search".
---

# JobHunter run (daily pipeline)

Read `../../reference/conventions.md` (relative to this skill's base directory). Load `jobhunter.yaml` and `profile/profile.yaml`. If the workspace is missing → tell the user to run `/jobhunter:setup` and stop.

`--scheduled` = unattended: ask no questions, never submit, never send email; on blockers (not signed in, connector missing) skip that part and record it in the digest.

## Pipeline
1. **Preflight** (≤ 1 min): workspace OK; Notion + Gmail tools present (ToolSearch); browser reachable and LinkedIn signed in (open `linkedin.com/feed/` once). Record what's unavailable.
2. **Sync** — run the workflow in `../sync/SKILL.md` (scheduled mode). Interview invites and offers go to the top of the digest.
3. **Hunt** — run `../hunt/SKILL.md` (scheduled mode). Produces Notion rows with Status `Suggested`.
4. **Prepare** — for the top `limits.pre_tailor_top` new suggestions (score ≥ `limits.min_score`, legitimacy not Suspicious): run the tailor workflow `../tailor/SKILL.md` (agents in parallel, max `limits.parallel_agents`). Keep their Status `Suggested`, set Next Action "Documents ready — move to To Apply to send". Also prepare any rows the user already moved to `To Apply` that have no documents yet (Status → `Prepared`).
5. **Follow-ups** — included in sync (drafts only).
6. **Digest** — write `jobs/<date>-run.md` and, if a notification tool exists (ToolSearch `notification`/`PushNotification`), send a short summary; attended runs show it in chat. In `language.ui`:
```
JobHunter · <date>
📬 Inbox: 1 interview invite (Acme, Tue 14:00) · 2 rejections · 1 viewed
🔎 Hunt: 412 scanned → 96 new → 31 passed filters → 14 suggested (3 strong)
📝 Ready to send: 5 (3 new + 2 from your To Apply list)
⚠️ Needs you: LinkedIn sign-in expired · 2 portal applications ready for assisted mode (Workday, SuccessFactors) — ~1–2 min each in /jobhunter:apply · 1 application to confirm via email link
Top today:
 1. 88  Data Analyst — Acme (Berlin · Hybrid · Easy Apply) — SQL/Power BI exact; gap: dbt   [docs ready]
 2. …
Next: review in Notion → To Apply → run /jobhunter:apply
```
7. Update `last_hunt_at` / `last_sync_at`.

## Failure handling
Each stage is independent: a failure in one stage is logged and the next stage still runs. On LinkedIn stop signals, skip all remaining LinkedIn browser work for the day.
