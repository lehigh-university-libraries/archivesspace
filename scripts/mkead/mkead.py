#!/usr/bin/env python3
"""
Export EAD XML for every published + completed resource across all repositories,
except those listed in MKEAD_EXCLUDE_REPOS. Filenames derive from each ead_id.

Always writes mkead-output.csv (next to this script) describing every record
scanned: what was exported, what was skipped, and why.

Config comes from .env in this directory (see .env.example).
  --dry-run   report only; write no EAD files (mkead-output.csv is still written)
"""
import os
import sys
import re
import csv
import argparse
from collections import defaultdict, Counter

import requests

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
CSV_PATH = os.path.join(SCRIPT_DIR, "mkead-output.csv")


def load_env():
    """Minimal .env loader (KEY=value per line). .env wins over existing env vars."""
    path = os.path.join(SCRIPT_DIR, ".env")
    if os.path.isfile(path):
        with open(path) as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ[k.strip()] = v.strip().strip("'").strip('"')


load_env()

AS_URL = os.environ.get("MKEAD_AS_URL", "http://localhost:8089")
AS_USER = os.environ.get("MKEAD_AS_USER")
AS_PASS = os.environ.get("MKEAD_AS_PASS")
OUTPUT_DIR = os.environ.get("MKEAD_OUTPUT_DIR")
STAFF_URL = os.environ.get("MKEAD_STAFF_URL", "").rstrip("/")
EXCLUDE_REPOS = {r.strip() for r in
                 os.environ.get("MKEAD_EXCLUDE_REPOS", "").split(",") if r.strip()}

EAD_PARAMS = {
    "include_unpublished": "false",
    "include_daos": "true",
    "numbered_cs": "true",
    "print_pdf": "false",
    "ead3": "false",
}

if not AS_USER or not AS_PASS:
    sys.exit("MKEAD_AS_USER and MKEAD_AS_PASS must be set (see .env.example)")
if not OUTPUT_DIR:
    sys.exit("MKEAD_OUTPUT_DIR must be set (see .env.example)")


def safe_filename(ead_id):
    cleaned = re.sub(r"[^A-Za-z0-9._-]", "_", ead_id.strip())
    return cleaned.strip("._-")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="report only; write no EAD files")
    args = ap.parse_args()

    s = requests.Session()
    r = s.post(f"{AS_URL}/users/{AS_USER}/login",
               data={"password": AS_PASS}, timeout=30)
    r.raise_for_status()
    token = r.json().get("session")
    if not token:
        sys.exit("Login succeeded but no session token returned")
    s.headers.update({"X-ArchivesSpace-Session": token})

    r = s.get(f"{AS_URL}/repositories", timeout=30)
    r.raise_for_status()
    repos = [x["uri"].split("/")[-1] for x in r.json()]
    repos = [x for x in repos if x not in EXCLUDE_REPOS]
    repo_names = {}
    for x in r.json():
        repo_names[x["uri"].split("/")[-1]] = x.get("repo_code") or x.get("name") or ""
    if EXCLUDE_REPOS:
        print(f"Excluding repositories: {','.join(sorted(EXCLUDE_REPOS))}", file=sys.stderr)
    print(f"Scanning repositories: {','.join(repos)}", file=sys.stderr)

    rows = []          # every record scanned
    candidates = []    # (repo, rid, fname, ead_id) passing the filter
    by_name = defaultdict(list)
    per_repo = defaultdict(Counter)

    for repo in repos:
        page = 1
        while True:
            r = s.get(f"{AS_URL}/repositories/{repo}/resources",
                      params={"page": page, "page_size": 100}, timeout=60)
            r.raise_for_status()
            data = r.json()
            for res in data.get("results", []):
                rid = res["uri"].rstrip("/").split("/")[-1]
                ead_id = (res.get("ead_id") or "").strip()
                title = (res.get("title") or "")[:80]
                publish = bool(res.get("publish"))
                status = res.get("finding_aid_status") or "<not set>"
                per_repo[repo]["scanned"] += 1

                row = {"repo": repo, "resource_id": rid, "ead_id": ead_id,
                       "title": title, "publish": publish,
                       "finding_aid_status": status,
                       "repository": repo_names.get(repo, repo),
                       "staff_url": (f"{STAFF_URL}/resources/{rid}"
                                     if STAFF_URL else "")}

                if not publish:
                    row.update(action="skipped", reason="not published")
                    per_repo[repo]["not published"] += 1
                elif status != "completed":
                    row.update(action="skipped",
                               reason=f"finding_aid_status={status}")
                    per_repo[repo][f"status {status}"] += 1
                elif not ead_id:
                    row.update(action="skipped", reason="no ead_id")
                    per_repo[repo]["no ead_id"] += 1
                else:
                    fname = safe_filename(ead_id) + ".xml"
                    row.update(action="export", reason="", filename=fname)
                    candidates.append((repo, rid, fname, ead_id))
                    by_name[fname].append((repo, rid, title))
                rows.append(row)
            if page >= data.get("last_page", 1):
                break
            page += 1

    # Collisions: export neither, report both.
    collisions = {k: v for k, v in by_name.items() if len(v) > 1}
    colliding = {k for k in collisions}
    if collisions:
        print("\nead_id COLLISIONS (both skipped -- filename is ambiguous):", file=sys.stderr)
        for fname, hits in collisions.items():
            print(f"  {fname}", file=sys.stderr)
            for repo, rid, title in hits:
                print(f"      repo {repo} res {rid}  {title}", file=sys.stderr)
                per_repo[repo]["collision"] += 1
        for row in rows:
            if row.get("filename") in colliding:
                row.update(action="skipped", reason="ead_id collision")
    candidates = [c for c in candidates if c[2] not in colliding]

    # Export
    failures = []
    if not args.dry_run:
        staging = os.path.join(OUTPUT_DIR, ".mkead-staging")
        os.makedirs(staging, exist_ok=True)
        for f in os.listdir(staging):
            os.remove(os.path.join(staging, f))

        for repo, rid, fname, ead_id in candidates:
            url = f"{AS_URL}/repositories/{repo}/resource_descriptions/{rid}.xml"
            try:
                rr = s.get(url, params=EAD_PARAMS, timeout=120)
                rr.raise_for_status()
                with open(os.path.join(staging, fname), "wb") as fh:
                    fh.write(rr.content)
                per_repo[repo]["exported"] += 1
            except requests.exceptions.RequestException as e:
                failures.append((repo, rid, fname, str(e)[:120]))
                per_repo[repo]["export FAILED"] += 1
                for row in rows:
                    if row["repo"] == repo and row["resource_id"] == rid:
                        row.update(action="skipped", reason=f"export failed: {str(e)[:80]}")

        # Swap staging into place: live dir is rebuilt from this run only,
        # so nothing orphaned from previous runs survives.
        for f in os.listdir(OUTPUT_DIR):
            if f.endswith(".xml"):
                os.remove(os.path.join(OUTPUT_DIR, f))
        for f in os.listdir(staging):
            os.replace(os.path.join(staging, f), os.path.join(OUTPUT_DIR, f))
        os.rmdir(staging)
    else:
        for repo, rid, fname, ead_id in candidates:
            per_repo[repo]["would export"] += 1

    # CSV
    cols = ["repo", "resource_id", "ead_id", "title", "publish",
            "finding_aid_status", "action", "reason", "filename",
            "repository", "staff_url"]
    with open(CSV_PATH, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for row in sorted(rows, key=lambda x: (int(x["repo"]), x["ead_id"])):
            w.writerow(row)

    # Summary
    print("\n=== summary ===", file=sys.stderr)
    for repo in repos:
        c = per_repo[repo]
        bits = "  ".join(f"{k}={v}" for k, v in sorted(c.items()) if k != "scanned")
        print(f"  repo {repo:>2}: scanned={c['scanned']:<5} {bits}", file=sys.stderr)
    if failures:
        print(f"\n{len(failures)} export FAILURE(S):", file=sys.stderr)
        for repo, rid, fname, err in failures:
            print(f"  repo {repo} res {rid} ({fname}): {err}", file=sys.stderr)
    verb = "would export" if args.dry_run else "exported"
    print(f"\n{verb} {len(candidates) - len(failures)} file(s)"
          + ("" if args.dry_run else f" to {OUTPUT_DIR}"), file=sys.stderr)
    print(f"details for all {len(rows)} scanned record(s): {CSV_PATH}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
