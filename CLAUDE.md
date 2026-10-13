# JobHunter plugin — rules for changing this repo

This repo is a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) with one plugin in `plugins/jobhunter/`. Users install it from GitHub with auto-update on, and **every commit pushed to `main` reaches every user at their next session** (no pinned version). Treat every change as a live upgrade of real people's job searches.

## Rule 1 — Never lose user data (non-negotiable, check on every change)

Users' data lives outside this repo: their **workspace folder** (`jobhunter.yaml`, `profile/`, `jobs/`, `applications/`, `interviews/`, `companies/`), their **Notion database** and their **Gmail**. Some users have scanned hundreds of jobs and applied to many; an update must never make any of that disappear, become unreadable, or get re-suggested as new.

1. **Additive only.** Never rename, move, or delete a workspace file, a config key, a Notion property, a Notion status value, a TSV column or a command name. Add new ones next to the old ones. Parsers must tolerate unknown/extra fields and missing new ones (missing key = documented default).
2. **If a format must change, write a migration** in `plugins/jobhunter/scripts/migrate.sh` (append a new numbered step at the end; never edit old steps). A migration must:
   - copy/convert, **never delete or overwrite** the original (keep it as a backup),
   - be **idempotent** (running it twice changes nothing) and **re-runnable** (an older plugin version in another open session may still write the old format — the migration must merge those writes later, like step M2 does),
   - be silent when there is nothing to do, and fast on large data (test with ~100k rows),
   - run automatically: every skill runs `migrate.sh` as step 0 (see `reference/conventions.md` §3). Users never run anything by hand.
3. **Notion changes are additive.** Skills may add missing properties or select options to the user's database (e.g. a new status); they never delete or rename the user's columns or options, and never overwrite the user's `Notes`. Column names can differ per user — always go through `jobhunter.yaml > notion.properties`.
4. **Stable identities.** Never change the plugin name, the marketplace name (`jobhunter`), the repo path, or command names. Users' installs, auto-update and scheduled tasks (`/jobhunter:run --scheduled`, `/jobhunter:sync --scheduled`) depend on them. Never re-add a pinned `"version"` to `plugin.json` (it would freeze auto-updates).
5. **Open sessions keep the old version** until `/reload-plugins` or a new session. Design changes so old and new versions can run side by side on the same workspace without corrupting it (append-only logs, atomic writes via temp file + `mv`).
6. **Safety rules are not data, but also never weaken them**: no auto-submit, no passwords/accounts/CAPTCHAs by Claude, email drafts only (see `reference/conventions.md` §6).

## Rule 2 — Test before pushing
- **Upgrade test:** build a throwaway workspace in the *previous* format (e.g. `jobpilot.yaml`, `jobs/seen.jsonl` with a few jobs incl. applied ones), run `scripts/migrate.sh` twice, and verify nothing was lost (`seen.sh stats`, `seen.sh lookup`), the old files still exist, and the second run prints nothing.
- **Script tests:** run every changed script on sample data (and on ~100k rows if it touches the index). Scripts must work with bash + POSIX awk + BSD sed (macOS) — use `sed -e ':a' -e '…' -e 'ta'`, no `gawk`/`gsed`/`grep -P` extensions.
- **Plugin checks:** `claude plugin validate .` and `claude plugin validate ./plugins/jobhunter` (the only accepted warning is "No version specified" — intentional).
- **Clean install test** without touching your own setup:
  ```bash
  CLAUDE_CONFIG_DIR="$(mktemp -d)" CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1 claude plugin install jobhunter --marketplace mertbezirgan/job-hunter-plugin
  ```
  then `claude plugin details jobhunter@jobhunter` must list all skills and agents.
- **Check git actually contains every new file** (`git status`, `git ls-files`): `.gitignore` patterns are root-anchored (`/profile/`, `/jobs/` …) because unanchored ones once silently excluded `reference/markets/` and `skills/insights/`.

## Rule 3 — Record it
Add an entry to `CHANGELOG.md` for every user-visible change, with a **Migration:** line ("none" or what `migrate.sh` does) and a **Compatibility:** line (what happens for users with open sessions / existing data).

## Repo conventions
- Plugin text (skills, agents, references) is English; Claude talks to the user in `language.ui`.
- Token efficiency: never read big workspace files into context (use `scripts/seen.sh`), read web pages with the extraction snippets in `reference/linkedin-playbook.md`, batch Notion writes, keep agent inputs compact. Routine agents/skills run on `model: sonnet`.
- Line endings LF (`.gitattributes`). No personal data in the repo.
- Commit messages end with the `Co-Authored-By` line from the session's attribution instructions.
