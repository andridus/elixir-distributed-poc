# Makefile for bank project (Elixir)
# All comments should be in English

.DEFAULT_GOAL := help

PROJECT_ROOT := ${PWD}
COMPOSE_FILE := $(PROJECT_ROOT)/deploy/docker-compose.yml
STACK_FILE := $(PROJECT_ROOT)/deploy/docker-stack.yml
PORTAINER_STACK := $(PROJECT_ROOT)/deploy/portainer-stack.yml
HOST_IP := $(shell hostname -I | awk '{print $$1}')

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  up           		 - Init Swarm, build image, deploy app"
	@echo "  status            - Show Swarm services status"
	@echo "  logs              - Tail bank service logs"
	@echo "  shell             - Attach remote Elixir shell to first instance"
	@echo "  list              - List replica container IDs and IPs"
	@echo "  scale             - Scale service: make scale <number>"
	@echo "  down         		 - Remove bank stack"

.PHONY: up
up:
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
	docker build -t bank:latest -f $(PROJECT_ROOT)/deploy/Dockerfile $(PROJECT_ROOT)
	# Deploy app stack
	docker stack deploy -c $(STACK_FILE) bank

.PHONY: status
status:
	docker stack services bank || true

.PHONY: logs
logs:
	docker service logs bank_bank -f

.PHONY: shell
shell:
	@CID=$$(docker ps -q --filter name=bank_bank | head -n1); \
	if [ -z "$$CID" ]; then \
		echo "bank_bank is not running. Start it with 'make dist-up'"; \
		exit 1; \
	fi; \
	echo "Connecting to the first bank app instance... (Ctrl+D to exit)"; \
	docker exec -it $$CID bin/bank remote

.PHONY: list
list:
	docker ps --filter name=bank_bank --format '{{.ID}} {{.Names}}' | while read cid name; do ip=$$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $$cid); echo $$cid $$ip $$name; done

scale:
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then echo "Usage: make scale <number>"; exit 1; fi
	docker service scale bank_bank=$(word 2,$(MAKECMDGOALS))
	@:

%:
	@:

.PHONY: dist-down
down:
	- docker stack rm bank || true
