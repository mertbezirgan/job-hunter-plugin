#!/usr/bin/env bash
# Deterministic grounding check: every number in a generated document must appear in a source file.
# Usage: fact_check.sh <draft.html|.txt> --sources <file>... [--context <file>...]
#   --sources : primary sources (master-cv.md, profile.yaml, answers.yaml)
#   --context : allowed non-candidate context (job.md) — numbers found only here are reported as "from posting"
# Exit code 0 = all grounded, 1 = ungrounded numbers found, 2 = usage error.
set -uo pipefail

[ $# -lt 3 ] && { echo "usage: fact_check.sh <draft> --sources <files…> [--context <files…>]" >&2; exit 2; }
draft="$1"; shift
sources=(); context=(); mode=""
for a in "$@"; do
  case "$a" in
    --sources) mode=s ;;
    --context) mode=c ;;
    *) [ "$mode" = s ] && sources+=("$a"); [ "$mode" = c ] && context+=("$a") ;;
  esac
done
[ ${#sources[@]} -eq 0 ] && { echo "no --sources given" >&2; exit 2; }

# Plain text: tags and entities removed, URLs / emails / phone numbers removed,
# thousands separators dropped (62.000 / 62,000 / 62 000 -> 62000).
norm() {
  sed -e 's/<[^>]*>/ /g' -e 's/&nbsp;/ /g' -e 's/&[a-z]*;/ /g' "$@" 2>/dev/null \
  | sed -E 's#https?://[^ ]+# #g' \
  | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/ /g' \
  | sed -E 's/\+[0-9][0-9 ()/-]{7,}[0-9]/ /g' \
  | sed -E -e ':a' -e 's/([0-9])[., ]([0-9]{3})([^0-9]|$)/\1\2\3/g' -e 'ta'
}

has_num() { grep -qE "(^|[^0-9])${1//./\\.}([^0-9]|$)"; }

src_text="$(norm "${sources[@]}")"
ctx_text=""; [ ${#context[@]} -gt 0 ] && ctx_text="$(norm "${context[@]}")"
draft_text="$(norm "$draft" | tr '\n' ' ')"

tokens="$(printf '%s' "$draft_text" | grep -oE '[0-9]+([.,][0-9]+)?' | sort -u)"

bad=0; from_ctx=()
for t in $tokens; do
  [ ${#t} -lt 2 ] && continue   # single digits: list numbers, months — too noisy
  printf '%s' "$src_text" | has_num "$t" && continue
  if [ -n "$ctx_text" ] && printf '%s' "$ctx_text" | has_num "$t"; then from_ctx+=("$t"); continue; fi
  snippet="$(printf '%s' "$draft_text" | grep -oE ".{0,60}(^|[^0-9])${t//./\\.}([^0-9]|$).{0,40}" | head -1)"
  echo "UNGROUNDED  $t  …${snippet}…"
  bad=1
done
[ ${#from_ctx[@]} -gt 0 ] && echo "FROM POSTING (fine if it refers to the job, e.g. a reference number): ${from_ctx[*]}"
[ $bad -eq 0 ] && echo "OK: all numbers grounded in sources"
exit $bad
