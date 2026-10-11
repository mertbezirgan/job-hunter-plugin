#!/usr/bin/env bash
# Render an HTML file to PDF with headless Chrome / Edge / Chromium. No extra installs.
# Usage: render_pdf.sh <input.html> <output.pdf>
set -euo pipefail

in="${1:?usage: render_pdf.sh <input.html> <output.pdf>}"
out="${2:?usage: render_pdf.sh <input.html> <output.pdf>}"

candidates=(
  "${JOBHUNTER_CHROME:-}"
  "/c/Program Files/Google/Chrome/Application/chrome.exe"
  "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
  "${LOCALAPPDATA:-/nonexistent}/Google/Chrome/Application/chrome.exe"
  "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
  "/c/Program Files/Microsoft/Edge/Application/msedge.exe"
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
  "/Applications/Chromium.app/Contents/MacOS/Chromium"
  "$(command -v google-chrome 2>/dev/null || true)"
  "$(command -v chromium 2>/dev/null || true)"
  "$(command -v chromium-browser 2>/dev/null || true)"
  "$(command -v msedge 2>/dev/null || true)"
)

browser=""
for c in "${candidates[@]}"; do
  [ -n "$c" ] && [ -x "$c" ] && { browser="$c"; break; }
done
[ -z "$browser" ] && { echo "No Chrome/Edge/Chromium found. Set JOBHUNTER_CHROME to the browser executable." >&2; exit 1; }

abs_in="$(cd "$(dirname "$in")" && pwd)/$(basename "$in")"
abs_out="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

# Windows browsers need Windows paths.
if command -v cygpath >/dev/null 2>&1; then
  abs_in="$(cygpath -w "$abs_in")"
  abs_out="$(cygpath -w "$abs_out")"
  url="file:///${abs_in//\\//}"
else
  url="file://$abs_in"
fi

# Separate profile so it never touches the user's signed-in Chrome.
profile_dir="$(mktemp -d)"
trap 'rm -rf "$profile_dir"' EXIT
if command -v cygpath >/dev/null 2>&1; then profile_dir_arg="$(cygpath -w "$profile_dir")"; else profile_dir_arg="$profile_dir"; fi

"$browser" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
  --user-data-dir="$profile_dir_arg" --no-pdf-header-footer --print-to-pdf-no-header \
  --print-to-pdf="$abs_out" "$url" >/dev/null 2>&1

[ -s "$out" ] && echo "OK $out" || { echo "PDF render failed" >&2; exit 1; }
