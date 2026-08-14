# mkead — UPenn EAD export

Generates EAD XML for every ArchivesSpace resource that is **published** and has
**`finding_aid_status = completed`**, across all repositories except those listed in
`MKEAD_EXCLUDE_REPOS`. Filenames are derived from each resource's `ead_id`. The output
directory is rebuilt on every run (staging-then-swap), so it never accumulates orphans.

This replaces the older hand-maintained approaches (`scripts/ead-harvest/` and the
now-removed personal harvest scripts), which relied on a manually curated resource list.

## Files

- `mkead.py` — the export script
- `.env.example` — template for the per-host config file
- `.env` — real config (gitignored; created per host, holds the account password)
- `mkead-output.csv` — written next to the script on every run; one row per resource
  scanned, with the action taken and reason. Doubles as a data-quality report. (gitignored)
- `../systemd/mkead.service`, `../systemd/mkead.timer` — the nightly schedule

## Configuration (.env)

Copy `.env.example` to `.env` and set values:

- `MKEAD_AS_URL` — backend API base, normally `http://localhost:8089`
  (requires the `app` service to publish `127.0.0.1:8089:8089` in docker-compose.yml)
- `MKEAD_AS_USER` — the ArchivesSpace account to authenticate as (see permissions below)
- `MKEAD_AS_PASS` — that account's password
- `MKEAD_OUTPUT_DIR` — where the EAD files are written. Required, no default (so a
  typo can never silently overwrite the live feed). On prod this is the UPenn feed dir.
- `MKEAD_EXCLUDE_REPOS` — comma-separated repository ids to skip (e.g. Test / Accessions)
- `MKEAD_STAFF_URL` — staff UI base, used only to build clickable links in the CSV

.env wins over any conflicting shell environment variables.

## Permissions

The export only needs to read records. Create a dedicated account and add it to the
`repository-viewers` group in each repository you export from (the gear icon next to the
repository name -> Manage Groups -> Viewers). Do NOT give it admin or write access. Repos
in `MKEAD_EXCLUDE_REPOS` do not need the grant.

## Running

    python3 mkead.py            # export + write mkead-output.csv
    python3 mkead.py --dry-run  # report + write the CSV, but write no EAD files

The run makes one API call per matching resource, so it takes a few minutes.
Export failures are non-fatal (reported, run continues). Two resources sharing an ead_id
are both skipped and reported, rather than silently overwriting each other.

## Nightly schedule (systemd)

The units in ../systemd/ are the source of truth but are not auto-installed. On a host:

    sudo cp scripts/systemd/mkead.service scripts/systemd/mkead.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl start mkead.service      # test run; check systemctl status + journalctl
    sudo systemctl enable --now mkead.timer # enable the nightly 03:00 run

Verify with `systemctl list-timers mkead.timer`. Runs log to journald
(`journalctl -u mkead.service`), so failures are visible rather than silent.

## Fresh-host checklist

1. git pull the repo (brings the script, .env.example, and the systemd units)
2. Create .env from .env.example with real values (see above)
3. Ensure the backend is reachable at MKEAD_AS_URL (loopback port published in compose)
4. Create the read-only export account and grant repository-viewers per repo
5. Install and enable the systemd units (see above)
6. Run once manually and confirm the output directory + mkead-output.csv look right
