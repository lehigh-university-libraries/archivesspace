#!/usr/bin/env bash

set -eou pipefail

if [ -f .env ]; then
  # Export variables so docker-compose and this script can see them
  # shellcheck disable=SC1091
  source .env
else
  echo "Error: .env file not found." >&2
  ./scripts/init.sh
  # shellcheck disable=SC1091
  source .env
fi

if [ ! -f ./certs/cert.pem ]; then
  echo "Error: TLS cert not found. Generating one with mkcert." >&2
  ./scripts/init.sh
fi

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/profile.sh"

HTTP_PORT=80
HTTPS_PORT=443

HOST_INSECURE_PORT=$(find_port $HTTP_PORT "HTTP")
HOST_SECURE_PORT=$(find_port $HTTPS_PORT "HTTPS")
export HOST_INSECURE_PORT HOST_SECURE_PORT

docker compose up --remove-orphans -d

PROTOCOL="https"
FINAL_PORT="$HOST_SECURE_PORT"
DEFAULT_P=443

URL="$PROTOCOL://$AS_HOSTNAME"
if [ "$FINAL_PORT" != "$DEFAULT_P" ]; then
    URL="$URL:$FINAL_PORT"
fi

export MAX_RETRIES=10
./scripts/ping.sh > /dev/null 2>&1

echo "---------------------------------------------------"
echo "🚀 Site available at: $URL"
echo "---------------------------------------------------"

# don't open the URL if we're in GHA
if [ "${GITHUB_ACTIONS:-}" != "" ]; then
  exit 0
fi

# don't open the URL if we're in an SSH session
if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_CLIENT:-}" ] || [ -n "${SSH_TTY:-}" ]; then
  exit 0
fi

case "$(uname -s)" in
    Darwin*)    open "$URL" ;;
    Linux*)     if grep -qi microsoft /proc/version; then
                    powershell.exe Start-Process "$URL" # WSL
                else
                    xdg-open "$URL" # Standard Linux
                fi ;;
    CYGWIN*|MINGW*|MSYS*) start "$URL" ;; # Windows Native
    *)          echo "You can open $URL in your browser." ;;
esac
