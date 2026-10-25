#!/usr/bin/env bash
# Bring a JobHunter workspace up to the current layout. Run at the start of every skill.
# Rules: idempotent, never deletes or overwrites user data, keeps the old files as backups,
# prints nothing when there is nothing to do. Add new steps at the end; never edit old ones.
# Usage: migrate.sh <workspace>
set -euo pipefail
ws="${1:?usage: migrate.sh <workspace>}"
here="$(cd "$(dirname "$0")" && pwd)"
[ -d "$ws" ] || { echo "workspace not found: $ws" >&2; exit 2; }
log() { echo "migrate: $*"; }

# M1 (v0.2 -> jobhunter rename): jobpilot.yaml -> jobhunter.yaml (copy; original kept)
if [ -f "$ws/jobpilot.yaml" ] && [ ! -f "$ws/jobhunter.yaml" ]; then
  cp "$ws/jobpilot.yaml" "$ws/jobhunter.yaml"
  log "copied jobpilot.yaml -> jobhunter.yaml (old file kept)"
fi

# M2 (seen index): jobs/seen.jsonl -> jobs/seen.tsv. Re-runs only when the jsonl changed
# (e.g. an older plugin version in another session appended to it); seen.sh merges idempotently.
if [ -f "$ws/jobs/seen.jsonl" ]; then
  marker="$ws/jobs/.seen-jsonl-migrated"
  lines="$(wc -l < "$ws/jobs/seen.jsonl" | tr -d ' ')"
  if [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$lines" ]; then
    log "$(bash "$here/seen.sh" migrate "$ws")"
    echo "$lines" > "$marker"
  fi
fi

# M3 (assisted mode): portal account registry
if [ -d "$ws/profile" ] && [ ! -f "$ws/profile/portal-accounts.yaml" ]; then
  cp "$here/../templates/portal-accounts.example.yaml" "$ws/profile/portal-accounts.yaml"
  log "created profile/portal-accounts.yaml"
fi
# M4 (2026-10-25): the plugin now handles LinkedIn's redesigned search page itself. Workspaces that got a
# local stopgap note keep it (we never edit user files); just tell the user it can be removed.
if [ -f "$ws/jobhunter.yaml" ] && grep -q "linkedin_extract_2026_10" "$ws/jobhunter.yaml" && [ ! -f "$ws/jobs/.m4-notice-shown" ]; then
  log "the plugin now includes the LinkedIn redesign fix; the local workaround (tooling_notes.linkedin_extract_2026_10 in jobhunter.yaml, tools/linkedin-extract-cards.js) is no longer needed and can be removed — the plugin's playbook snippets take precedence"
  mkdir -p "$ws/jobs"; : > "$ws/jobs/.m4-notice-shown"
fi
# M5 (2026-10-25): company watchlist registry
if [ -d "$ws/profile" ] && [ ! -f "$ws/profile/companies.yaml" ]; then
  cp "$here/../templates/companies.example.yaml" "$ws/profile/companies.yaml"
  log "created profile/companies.yaml (company watchlist — add companies with /jobhunter:companies)"
fi
exit 0
