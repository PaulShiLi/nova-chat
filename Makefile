APPLICATION_NAME ?= nova
GIT_HASH ?= $(shell git log --format="%h" -n 1)
SHELL = /bin/bash
rootDir = $(dirname "${BASH_SOURCE[0]}")


### Comments ###

# Command names are listed below:

# --------------------------------------------------------------------------------------

help:
	@echo "\n--------------------------------------------------------------------------------------"
	@echo "\n\033[1;35m# Scripts #\033[0m\n"   # Purple color for the section header
	@echo "\033[1;32m# Will install required dependencies for development\033[0m"   # Green color for the description
	@echo "\033[1;33mmake setup\033[0m"   # Yellow color for the command
	@echo "--------------------------------------------------------------------------------------"
	@echo "\n"

# -------------------------------------------------------------------------------------- 
# --- Bash Scripts ---
# --------------------------------------------------------------------------------------

setup:
	. .$(rootDir)/build.sh

# -------------------------------------------------------------------------------------- 
# --- Commands ---
# --------------------------------------------------------------------------------------

docker-up:
	docker compose -f docker-compose.yml up --force-recreate

docker-down:
	docker compose -f docker-compose.yml down

docker-build:
	DOCKER_BUILDKIT=1 docker compose -f docker-compose.yml build

docker-rebuild:
	DOCKER_BUILDKIT=1 docker compose -f docker-compose.yml up --force-recreate --build
