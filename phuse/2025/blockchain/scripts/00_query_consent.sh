#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

pushd "$FS/test-network" >/dev/null

# Satisfy envVar.sh expectations
export VERBOSE=${VERBOSE:-false}
export OVERRIDE_ORG=${OVERRIDE_ORG:-""}
export USING_COUCHDB=${USING_COUCHDB:-false}
export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-test-network}
export CONTAINER_CLI=${CONTAINER_CLI:-docker}
export CONTAINER_CLI_COMPOSE=${CONTAINER_CLI_COMPOSE:-"docker compose"}
export DOCKER_SOCK=${DOCKER_SOCK:-/var/run/docker.sock}

. ./scripts/envVar.sh

setGlobals 1
peer chaincode query -C clinicaltrial -n clinicalcc -c '{"Args":["GetConsent","SUBJ001_v2"]}'
popd >/dev/null

