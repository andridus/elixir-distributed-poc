# Makefile for banking_core project
# All comments should be in English

.DEFAULT_GOAL := help

PROJECT_ROOT := ${PWD}
COMPOSE_FILE := $(PROJECT_ROOT)/distributed/docker-compose.yml
STACK_FILE := $(PROJECT_ROOT)/distributed/docker-stack.yml
PORTAINER_STACK := $(PROJECT_ROOT)/distributed/portainer-stack.yml
HOST_IP := $(shell hostname -I | awk '{print $$1}')

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  dev-up            - Start dev environment (docker-compose)"
	@echo "  dev-down          - Stop dev environment (docker-compose)"
	@echo "  dev-logs          - Tail logs (docker-compose)"
	@echo "  dist-up           - Init Swarm, build image, deploy app"
	@echo "  portainer-up      - Deploy Portainer stack"
	@echo "  status            - Show Swarm services status"
	@echo "  logs              - Tail banking_core service logs"
	@echo "  shell             - Attach remote Erlang shell to first instance"
	@echo "  list              - List replica container IDs and IPs"
	@echo "  scale             - Scale service: make scale <number>"
	@echo "  portainer-url     - Print Portainer access URL"
	@echo "  dist-down         - Remove bank stack"
	@echo "  portainer-down    - Remove Portainer stack"

# ---------------------
# docker-compose (dev)
# ---------------------
.PHONY: dev-up
dev-up:
	docker compose -f $(COMPOSE_FILE) up -d

.PHONY: dev-down
dev-down:
	docker compose -f $(COMPOSE_FILE) down

.PHONY: dev-logs
dev-logs:
	docker compose -f $(COMPOSE_FILE) logs -f

# ---------------------
# Docker Swarm (distributed dev)
# ---------------------
.PHONY: dist-up
dist-up:
	@if [ "$$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then \
		echo "Initializing Docker Swarm..."; \
		docker swarm init || true; \
	fi
	@# Ensure overlay network exists
	@if ! docker network ls --format '{{.Name}}' | grep -q '^swarm_bank_net$$'; then \
		echo "Creating overlay network swarm_bank_net..."; \
		docker network create --driver overlay swarm_bank_net; \
	fi
	@# Build image
	docker build -t banking_core:latest -f $(PROJECT_ROOT)/distributed/Dockerfile $(PROJECT_ROOT)
	# Deploy app stack
	docker stack deploy -c $(STACK_FILE) bank

.PHONY: portainer-up
portainer-up:
	@if [ "$$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then \
		echo "Initializing Docker Swarm..."; \
		docker swarm init || true; \
	fi
	@# Ensure overlay network exists
	@if ! docker network ls --format '{{.Name}}' | grep -q '^swarm_bank_net$$'; then \
		echo "Creating overlay network swarm_bank_net..."; \
		docker network create --driver overlay swarm_bank_net; \
	fi
	# Deploy Portainer stack
	docker stack deploy -c $(PORTAINER_STACK) portainer
	@echo "--"
	@echo "Waiting for services to stabilize..." && sleep 5

.PHONY: status
status:
	docker stack services bank || true
	docker stack services portainer || true

.PHONY: logs
logs:
	docker service logs bank_banking_core -f

.PHONY: portainer-url
portainer-url:
	@echo "Portainer: https://$(HOST_IP):9443  (or http://$(HOST_IP):9000)"
	@echo "On first access, create admin user and select the local endpoint."

.PHONY: shell
shell:
	@CID=$$(docker ps -q --filter name=bank_banking_core | head -n1); \
	if [ -z "$$CID" ]; then \
		echo "bank_banking_core is not running. Start it with 'make dist-up'"; \
		exit 1; \
	fi; \
	echo "Connecting to the first banking_core app instance... (Ctrl+D to exit)"; \
	docker exec -it $$CID bin/banking_core remote_console

.PHONY: list
list:
	docker ps --filter name=bank_banking_core --format '{{.ID}} {{.Names}}' | while read cid name; do ip=$$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $$cid); echo $$cid $$ip $$name; done

scale:
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then echo "Usage: make scale <number>"; exit 1; fi
	docker service scale bank_banking_core=$(word 2,$(MAKECMDGOALS))
	@:

%:
	@:

.PHONY: dist-down
dist-down:
	- docker stack rm bank || true
	- docker network rm swarm_bank_net || true

.PHONY: portainer-down
portainer-down:
	- docker stack rm portainer || true
