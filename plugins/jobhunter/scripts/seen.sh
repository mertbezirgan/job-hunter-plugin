#!/usr/bin/env bash
# JobHunter seen-jobs index: fast dedup without ever loading the history into Claude's context.
#
# Index file: <workspace>/jobs/seen.tsv (no header), one job per line:
#   id  key  first_seen  last_seen  status  title  company  location  url
#   key = normalised "company|title|city" (gender tags and legal forms removed) - catches the
#   same job listed on several sites.
#
# Candidate input (stdin) is TSV:  id  title  company  location  url   (extra columns are ignored)
#
# Commands (workspace = folder containing jobhunter.yaml):
#   seen.sh migrate  <ws>            import jobs/seen.jsonl (older versions) into seen.tsv; idempotent, keeps the jsonl
#   seen.sh new      <ws> < cand     print only candidates not seen before (by id or key, also within the batch)
#   seen.sh add      <ws> <status> < cand   insert new jobs with <status>; existing ids get last_seen=today
#   seen.sh status   <ws> < "id<TAB>status" lines   update statuses
#   seen.sh lookup   <ws> < ids      print "id<TAB>status" for known ids
#   seen.sh reposts  <ws> < ids      print "id<TAB>listings_with_same_key<TAB>first_seen_of_key"
#   seen.sh stats    <ws>            counts by status
# Portable: bash + POSIX awk (macOS, Linux, Windows Git Bash). Writes are atomic (temp file + mv).
set -euo pipefail

cmd="${1:-}"; ws="${2:-}"
if [ -z "$cmd" ] || [ -z "$ws" ]; then sed -n '2,19p' "$0"; exit 2; fi
[ -d "$ws" ] || { echo "workspace not found: $ws" >&2; exit 2; }
mkdir -p "$ws/jobs"
idx="$ws/jobs/seen.tsv"; [ -f "$idx" ] || : > "$idx"
today="$(date +%Y-%m-%d)"

# Shared awk helpers. The index is always loaded with getline in BEGIN (works when it is empty).
AWK_LIB='
function clean(s) { gsub(/\t|\r|\n/, " ", s); return s }
function norm(s,   i) {
  s = tolower(s)
  gsub(/\((m|w|f|d|x|all|gn|div|mwd|wmd)[^)]*\)/, " ", s)      # (m/w/d) (w/m/d) (f/m/x) (all genders) (gn)
  gsub(/[mwfdx] *\/ *[mwfdx] *\/ *[mwfdx]/, " ", s)              # m/w/d without brackets
  gsub(/[[:punct:]]+/, " ", s)
  s = " " s " "
  for (i = 0; i < 2; i++)
    gsub(/ (gmbh|mbh|ag|se|kg|kgaa|ohg|ug|ltd|limited|inc|llc|plc|bv|nv|sa|sas|srl|spa|co|corp|group|holding) /, " ", s)
  gsub(/ +/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s)
  return s
}
function city(loc,   p) { split(loc, p, ","); return norm(p[1]) }
function mkkey(title, company, loc) { return norm(company) "|" norm(title) "|" city(loc) }
function mkurl(id, u) { if (u == "" && id ~ /^li:[0-9]+$/) u = "https://www.linkedin.com/jobs/view/" substr(id, 4) "/"; return u }
function loadidx(path,   line, f) {
  while ((getline line < path) > 0) {
    if (line ~ /^#/ || line == "") continue
    split(line, f, "\t")
    seen[f[1]] = 1; key[f[2]] = 1; stat[f[1]] = f[5]; kof[f[1]] = f[2]
    cnt[f[2]]++; if (!(f[2] in first) || f[3] < first[f[2]]) first[f[2]] = f[3]
  }
  close(path)
}
'

write_atomic() { local tmp="$idx.tmp.$$"; cat > "$tmp"; mv "$tmp" "$idx"; }

case "$cmd" in
  migrate)
    src="$ws/jobs/seen.jsonl"
    [ -f "$src" ] || { echo "nothing to migrate"; exit 0; }
    before=$(wc -l < "$idx" | tr -d ' ')
    { cat "$idx"; awk -v idx="$idx" -v today="$today" "$AWK_LIB"'
      function jget(line, k,   m) {
        if (match(line, "\"" k "\"[ ]*:[ ]*\"[^\"]*\"")) {
          m = substr(line, RSTART, RLENGTH); sub(/^"[^"]*"[ ]*:[ ]*"/, "", m); sub(/"$/, "", m); return m
        }
        return ""
      }
      BEGIN { loadidx(idx) }
      {
        id = jget($0, "source_id"); if (id == "") id = jget($0, "id"); if (id == "") next
        if (id ~ /^[0-9]+$/) id = "li:" id
        if (id in seen) next
        t = clean(jget($0, "title")); c = clean(jget($0, "company")); l = clean(jget($0, "location"))
        u = clean(jget($0, "url")); st = jget($0, "status"); fd = jget($0, "found")
        if (st == "") st = "seen"; if (fd == "") fd = today
        seen[id] = 1
        print id "\t" mkkey(t, c, l) "\t" fd "\t" fd "\t" st "\t" t "\t" c "\t" l "\t" u
      }' "$src"; } | write_atomic
    after=$(wc -l < "$idx" | tr -d ' ')
    echo "migrated $((after - before)) jobs from seen.jsonl (index now $after jobs; seen.jsonl kept as backup)"
    ;;

  new)
    awk -F'\t' -v idx="$idx" "$AWK_LIB"'
      BEGIN { loadidx(idx) }
      $0 == "" { next }
      { n++
        if ($1 == "" || ($1 in seen)) { dup_id++; next }
        k = mkkey($2, $3, $4)
        if (k in key) { dup_key++; next }
        seen[$1] = 1; key[k] = 1; new++
        print
      }
      END { printf "in: %d · already seen: %d · same job from another source: %d · new: %d\n", n, dup_id, dup_key, new > "/dev/stderr" }'
    ;;

  add)
    status="${3:?usage: seen.sh add <ws> <status> < candidates.tsv}"
    cand="$(mktemp)"; trap 'rm -f "$cand"' EXIT
    cat > "$cand"
    awk -F'\t' -v OFS='\t' -v cand="$cand" -v today="$today" -v st="$status" "$AWK_LIB"'
      BEGIN {
        while ((getline line < cand) > 0) {
          if (line == "") continue
          split(line, f, "\t"); if (f[1] == "" || (f[1] in row)) continue
          row[f[1]] = line; order[++m] = f[1]
        }
      }
      ($1 in row) { $4 = today; done[$1] = 1 }
      { print }
      END {
        for (i = 1; i <= m; i++) { id = order[i]; if (id in done) continue
          split(row[id], f, "\t")
          print id, mkkey(f[2], f[3], f[4]), today, today, st, clean(f[2]), clean(f[3]), clean(f[4]), mkurl(id, clean(f[5]))
        }
      }' "$idx" | write_atomic
    echo "index now $(wc -l < "$idx" | tr -d ' ') jobs"
    ;;

  status)
    upd="$(mktemp)"; trap 'rm -f "$upd"' EXIT
    cat > "$upd"
    awk -F'\t' -v OFS='\t' -v upd="$upd" -v today="$today" '
      BEGIN { while ((getline line < upd) > 0) { split(line, f, "\t"); if (f[1] != "") s[f[1]] = f[2] } }
      ($1 in s) { $5 = s[$1]; $4 = today; n++ }
      { print }
      END { printf "updated %d\n", n > "/dev/stderr" }' "$idx" | write_atomic
    ;;

  lookup)
    awk -v idx="$idx" "$AWK_LIB"'BEGIN { loadidx(idx) } ($1 in seen) { print $1 "\t" stat[$1] }'
    ;;

  reposts)
    awk -v idx="$idx" "$AWK_LIB"'BEGIN { loadidx(idx) } ($1 in seen) { print $1 "\t" cnt[kof[$1]] "\t" first[kof[$1]] }'
    ;;

  stats)
    awk -F'\t' '$0 != "" { c[$5]++; n++ } END { printf "total %d\n", n; for (s in c) printf "%s\t%d\n", s, c[s] }' "$idx"
    ;;

  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
