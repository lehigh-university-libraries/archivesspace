# EAD Harvest

Nightly harvest of EAD XML files for UPenn. Writes to `plugins/lehigh/public/assets/ATexports/`.

## Setup

1. Copy `.env.example` to `.env` and set `AS_PASS` (password for the `asUpennHarvest` AS user).
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
