#!/usr/bin/env bash

set -eou pipefail

if [ ! -f .env ]; then
  cp .env.example .env
fi

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/profile.sh"

./scripts/generate-certs.sh

# shellcheck disable=SC1091
source .env

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
  update_env "MYSQL_ROOT_PASSWORD" "$(openssl rand -hex 16)"
fi
if [ -z "${MYSQL_PASSWORD:-}" ]; then
  update_env "MYSQL_PASSWORD" "$(openssl rand -hex 16)"
fi
