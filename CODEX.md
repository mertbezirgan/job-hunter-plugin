# Use JobHunter with Codex

Open **this repository folder** in Codex and ask:

> Use $jobhunter to set up my search from my CV. Keep my data local, learn my
> preferences, and use a local tracker. Do not submit applications.

The repo-local skill lives at `.agents/skills/jobhunter/SKILL.md`; `AGENTS.md`
routes natural-language job-search requests to it too. If your current session
doesn't discover the new skill, start a new chat in this folder, or explicitly
ask it to read that file. You do not need to install the Claude plugin.
This follows OpenAI's [local skill discovery](https://learn.chatgpt.com/docs/build-skills)
and [repository instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Setup

Codex can run setup for you. The manual bootstrap is:

```sh
python3 plugins/jobhunter/scripts/init_workspace.py . --cv "/path/to/CV.pdf"
```

Windows PowerShell:

```powershell
py -3 plugins/jobhunter/scripts/init_workspace.py . --cv 'C:\path\to\CV.pdf'
```

Use an installed Python 3.9+ or the app's bundled Python. The script creates
missing settings and copies the CV; the agent then extracts and verifies the CV,
asks useful preference questions, and creates a private search brief. Rerunning
setup preserves existing files. Import a revised CV explicitly rather than
overwriting the original. For a legacy `jobpilot.yaml` workspace, run the existing
migration first. Never initialise user data inside `plugins/jobhunter`.

The existing tracking/migration/number-check helpers need Bash + awk/sed. On
Windows, use Git Bash from Git for Windows, not an unconfigured WSL `bash.exe`.
Pass paths to the shell helpers with forward slashes (`C:/path/with spaces`).
PDF rendering can use available artifact tools or the existing Chrome/Edge helper.
Notion, Gmail, JobSpy and recurring automations are optional.

## Everyday requests

- “Find new jobs matching my preferences; show evidence and the biggest gap.”
- “Read my LinkedIn Applied history, import it, and infer search preferences.”
- “Evaluate this job: [link].”
- “Tailor my CV for this posting and verify every claim.”
- “Prepare applications for jobs 1 and 3; show me each before submission.”
- “Prepare me for the interview at [company].”
- “Check the companies on my watchlist.”
- “Run the search and prepare the top three applications.”

These are natural-language requests, not Claude slash commands. `$jobhunter`
can prefix any of them. The single skill routes to all ten workflow modes.
Only tools available in the current Codex environment can be used; signed-in
LinkedIn access must be verified separately from public web search. If browser
access is blocked, supply links/pasted history and continue public research.

## Private data and shared code

The repo root doubles as the default private workspace: `profile/`, `jobs/`,
`applications/`, `interviews/`, `companies/`, `insights/`, `markets/`,
`jobhunter.yaml`, `tmp/`, `output/` and `private/` are ignored by Git. Personal
details belong there, not in the skill, `AGENTS.md`, examples, or PR text.
An ignore rule cannot untrack a file already committed; inspect staged changes.

The local tracker reuses `jobs/seen.tsv` and `scripts/seen.sh`. Full evaluations,
applied dates, confirmation evidence and next actions live in per-job records.
Imported history prevents duplicate recommendations; an incomplete import is
reported as incomplete. A missing salary is kept unknown, not treated as a fail.
Unknown eligibility and availability are never filled from assumptions.

The Claude installation and commands continue to work unchanged. The Codex
settings default to local tracking and disabled email/scheduling; they are an
opt-in workspace choice, not a replacement for a configured Claude workspace.
Do not run concurrent tracker writes from both assistants.

## ChatGPT

Use [CHATGPT.md](CHATGPT.md) for a copy-and-upload workflow when ChatGPT cannot
read the local repository. It does not assume local file access, browser control,
connectors, scheduling or shell execution.

## Validation

```sh
python3 -m unittest discover -s tests -v
```

The compatibility tests reuse the existing shell scripts against disposable
workspaces, including legacy migration, duplicate applications and a 100k-row
index. Set `JOBHUNTER_BASH` to Git Bash on Windows if necessary. These tests do
not sign in, apply for jobs, send email or read personal workspace data.
