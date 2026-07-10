# EAD Harvest

Nightly harvest of EAD XML files for UPenn. Writes to `plugins/lehigh/public/assets/ATexports/`.

## Requirements

- The ArchivesSpace backend API must be reachable at the URL in `HARVEST_AS_URL` (default `http://localhost:8089`). In the Docker setup this requires the `app` service to publish `127.0.0.1:8089:8089` in `docker-compose.yml`.
- `jq` and `curl` must be installed on the host (the script runs on the host, not in a container).
- Backend API routes have no `/api` prefix (login is `/users/<user>/login`).

## Setup

1. Copy `.env.example` to `.env` and set `HARVEST_AS_PASS` (password for the `asUpennHarvest` AS user). `HARVEST_AS_URL` and `HARVEST_AS_USER` are also read from `.env`.
2. Install systemd units:

       sudo cp scripts/systemd/ead-harvest.service /etc/systemd/system/
       sudo cp scripts/systemd/ead-harvest.timer /etc/systemd/system/
       sudo systemctl daemon-reload
       sudo systemctl enable --now ead-harvest.timer

## Files

- `harvest.sh` — script
- `resources.csv` — filename,repo_id,resource_id (one per line)
- `.env` — credentials (gitignored)
- `.env.example` — template

## Adding/removing resources

Edit `resources.csv`.

## Manual run

    ./harvest.sh
