.PHONY: help
.PHONY: build pull down down-% logs-% up up-%
.PHONY: clean init ping status
.SILENT:

DEFAULT_HTTP=80
DEFAULT_HTTPS=443

help: ## Show this help message
	echo 'Usage: make [target]'
	echo ''
	echo 'Available targets:'
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%s\033[0m\t%s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort | column -t -s $$'\t'

pull:
	docker compose pull --ignore-buildable --ignore-pull-failures

init: ## Get the host machine configured to run ISLE
	./scripts/init.sh

up: ## Start docker compose project with smart port allocation
	./scripts/up.sh

up-%:  ## Start a specific service (e.g., make up-drupal)
	docker compose up $* -d

down:  ## Stop/remove the docker compose project's containers and network.
	docker compose down

down-%:  ## Stop/remove a specific service (e.g., make down-traefik)
	docker compose down $*

logs-%:  ## Look at logs for a specific service (e.g., make logs-drupal)
	docker compose logs $* --tail 20 -f

clean:  ## Delete all stateful data.
	./scripts/clean.sh

ping:  ## Ensure site is available.
	./scripts/ping.sh

lehigh-certs: ## Place Lehigh's certs into traefik's cert store
	sudo ./scripts/lehigh-certs.sh
