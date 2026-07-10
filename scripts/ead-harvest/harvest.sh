#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
  set +a
fi

set -euo pipefail

AS_URL="${HARVEST_AS_URL:-http://localhost:8089}"
AS_USER="${HARVEST_AS_USER:?HARVEST_AS_USER env var required}"
AS_PASS="${HARVEST_AS_PASS:?HARVEST_AS_PASS env var required}"
OUTPUT_DIR="${OUTPUT_DIR:-/opt/archivesspace/plugins/lehigh/public/assets/ATexports}"
RESOURCES_FILE="$(dirname "$0")/resources.csv"

EAD_PARAMS="include_unpublished=false&include_daos=true&numbered_cs=true&print_pdf=false&ead3=false"

# Login
json=$(curl -sf -F "password=$AS_PASS" "$AS_URL/users/$AS_USER/login")
token=$(jq -r ".session" <<<"$json")

if [[ -z "$token" || "$token" == "null" ]]; then
  echo "Login failed" >&2
  exit 1
fi

# Only after a successful login, clear previously-harvested XML so renamed/removed
# resources do not leave orphans. A login/connection failure exits before this
# (set -e), leaving the existing good exports intact.
rm -f "$OUTPUT_DIR"/*.xml

# Harvest each resource (skip header line)
tail -n +2 "$RESOURCES_FILE" | while IFS=',' read -r filename repo_id resource_id; do
  [[ -z "$filename" ]] && continue
  curl -sf --output "$OUTPUT_DIR/$filename" \
    -H "X-ArchivesSpace-Session:$token" \
    "$AS_URL/repositories/$repo_id/resource_descriptions/$resource_id.xml?$EAD_PARAMS" \
    || echo "Failed: $filename (repo=$repo_id, resource=$resource_id)" >&2
done
