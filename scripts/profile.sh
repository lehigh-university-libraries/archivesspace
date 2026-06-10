#!/usr/bin/env bash

set -euf -o pipefail

RESET=$(tput sgr0)
RED=$(tput setaf 9)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 6)
YELLOW=$(tput setaf 3)
readonly RESET RED GREEN BLUE YELLOW
# Export color codes for use by sourcing scripts
export RESET RED GREEN BLUE YELLOW

# Alias for echo -e to avoid shellcheck warnings about printf format strings
# shellcheck disable=SC2039,SC3044
echo_e() {
    echo -e "$@"
}

update_env() {
    local var="$1"
    local val="$2"

    if grep -Eq "^${var}=" .env; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/^${var}=.*/${var}=${val}/" .env
        else
            sed -i "s/^${var}=.*/${var}=${val}/" .env
        fi
    else
        printf '%s=%s\n' "$var" "$val" >> .env
    fi
}

# Function to check if a port is in use
# Works on Linux, macOS, and WSL
is_port_in_use() {
    local port=$1
    # Try ss first (available on most Linux/WSL systems)
    # Use -tln without -H for compatibility, filter with grep
    if command -v ss >/dev/null 2>&1; then
        ss -tln 2>/dev/null | grep -q ":${port}\b"
        return $?
    fi
    # Fall back to lsof (available on macOS and some Linux)
    if command -v lsof >/dev/null 2>&1; then
        lsof -PiTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1
        return $?
    fi
    # Last resort: try netstat
    if command -v netstat >/dev/null 2>&1; then
        netstat -tln 2>/dev/null | grep -q ":${port}\b"
        return $?
    fi
    # If no tool available, assume port is free
    return 1
}

# Function to find the next available port
find_port() {
    local port=$1
    if [ "${DEVELOPMENT_ENVIRONMENT:-false}" = "false" ]; then
      printf "%s\n" "$port"
      return
    fi

    while true; do
        # Check if anything is listening on TCP at this port
        if ! is_port_in_use "$port"; then
            break # Port is completely free
        fi

        # If port is busy, check if it's our own docker project
        local container_id
        container_id=$(docker ps -q --filter "publish=$port" || true)

        if [ -n "$container_id" ]; then
            local c
            c=$(docker inspect "$container_id" --format '{{ index .Name }}' 2>/dev/null || echo "")
            if [ "$c" = "/traefik" ]; then
                printf "Port %s is already assigned to this project.\n" "$port" >&2
                break
            fi
        fi
        echo_e "${RED}Port $port is used by another process.${RESET}" >&2
        if [ "$port" = "80" ]; then
          port=8080
        elif [ "$port" = "443" ]; then
          port=8443
        else
          port=$((port + 1))
        fi

        echo_e "${YELLOW}Trying $port...${RESET}" >&2
    done
    printf "%s\n" "$port"
}

# --- Configuration Warnings ---
WARNINGS_FOUND=false
print_warning_header() {
    if [ "$WARNINGS_FOUND" = "false" ]; then
        echo_e "${RED}--- Configuration Warnings ---${RESET}"
        WARNINGS_FOUND=true
    fi
}

is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null || false
}

# --- Environment Check ---
if [ -f .env ]; then
  AS_HOSTNAME=$(grep '^AS_HOSTNAME=' .env | cut -d'=' -f2 | tr -d '"' || echo "localhost")
  export AS_HOSTNAME
else
  echo_e "  ${RED}.env file not found. Cannot determine configuration.${RESET}"
  echo "You should cp sample.env to .env"
  exit 1
fi

is_docker_rootless() {
    status_dev || docker info -f "{{println .SecurityOptions}}" | grep -qi rootless
}

has_no_docker_override() {
    status_dev || { [ ! -f docker-compose.override.yml ] && [ ! -L docker-compose.override.yml ]; }
}

is_using_non_standard_ports() {
    status_dev || [ "${HTTP_PORT:-80}" != "80" ] || [ "${HTTPS_PORT:-443}" != "443" ]
}

# Detect the host port that maps to 80
traefik_port_80() {
    docker compose port traefik 80 | cut -d: -f2
}

# Detect the host port that maps to 443
traefik_port_443() {
    docker compose port traefik 443 | cut -d: -f2
}
