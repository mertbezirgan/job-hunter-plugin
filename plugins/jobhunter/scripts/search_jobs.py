# /// script
# requires-python = ">=3.10"
# dependencies = ["python-jobspy>=1.1.80"]
# ///
"""Optional extra job sources (Indeed, Glassdoor, Google Jobs, LinkedIn public) via JobSpy.

Run with:  uv run search_jobs.py --terms "Data Analyst" "BI Analyst" --locations "Berlin, Germany" \
               --country germany --hours-old 72 --out jobs.json
Prints a JSON list of normalised jobs. Personal use, low volume.
"""
import argparse
import json
import sys

from jobspy import scrape_jobs


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--terms", nargs="+", required=True)
    p.add_argument("--locations", nargs="+", required=True)
    p.add_argument("--sites", nargs="+", default=["indeed", "glassdoor", "google", "linkedin"])
    p.add_argument("--country", required=True, help="country_indeed value, see JobSpy README")
    p.add_argument("--hours-old", type=int, default=72)
    p.add_argument("--remote", action="store_true")
    p.add_argument("--results", type=int, default=40)
    p.add_argument("--out", default="-")
    a = p.parse_args()

    seen, rows = set(), []
    for term in a.terms:
        for loc in a.locations:
            for site in a.sites:
                kwargs = dict(
                    site_name=[site],
                    search_term=term,
                    location=loc,
                    results_wanted=a.results,
                    country_indeed=a.country,
                    hours_old=a.hours_old,
                )
                if site == "google":
                    kwargs["google_search_term"] = f"{term} jobs near {loc} since {max(1, a.hours_old // 24)} days ago"
                if a.remote and site not in ("indeed", "linkedin"):
                    # Indeed/LinkedIn: hours_old cannot be combined with is_remote; remote handled by caller
                    kwargs["is_remote"] = True
                try:
                    df = scrape_jobs(**kwargs)
                except Exception as e:  # one failing site must not kill the run
                    print(f"[warn] {site} '{term}' @ '{loc}': {e}", file=sys.stderr)
                    continue
                for r in df.to_dict(orient="records"):
                    key = (str(r.get("company", "")).lower(), str(r.get("title", "")).lower(), str(r.get("location", "")).lower())
                    if key in seen:
                        continue
                    seen.add(key)
                    rows.append({
                        "source": site,
                        "source_id": str(r.get("id") or ""),
                        "title": r.get("title"),
                        "company": r.get("company"),
                        "location": r.get("location"),
                        "is_remote": r.get("is_remote"),
                        "job_type": r.get("job_type"),
                        "date_posted": str(r.get("date_posted") or ""),
                        "url": r.get("job_url"),
                        "direct_url": r.get("job_url_direct"),
                        "salary": " ".join(str(r.get(k) or "") for k in ("min_amount", "max_amount", "currency", "interval")).strip(),
                        "description": (r.get("description") or "")[:6000],
                    })

    data = json.dumps(rows, ensure_ascii=False, indent=1, default=str)
    if a.out == "-":
        print(data)
    else:
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(data)
        print(f"wrote {len(rows)} jobs to {a.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
