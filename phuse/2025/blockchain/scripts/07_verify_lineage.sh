#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

ANALYSIS_ID="ANALYSIS_001"

pushd "$FS/test-network" >/dev/null

# Set up Fabric binaries path
export PATH="${PWD}/../bin:$PATH"
export FABRIC_CFG_PATH="${PWD}/../config/"

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

LINEAGE_JSON=$(peer chaincode query -C clinicaltrial -n clinicalcc -c "{\"Args\":[\"GetLineage\",\"$ANALYSIS_ID\"]}")
popd >/dev/null

echo "Analysis Lineage Record:"
echo "$LINEAGE_JSON" | python3 -m json.tool

# Extract Merkle root
MERKLE_ROOT=$(echo "$LINEAGE_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['merkleRoot'])")

echo ""
echo -e "\033[0;32mLineage retrieved successfully.\033[0m Merkle Root=\033[1;33m$MERKLE_ROOT\033[0m"
echo ""
echo "This Merkle root cryptographically links:"
echo "  • Input datasets (DM.csv)"
echo "  • Statistical program (analysis_program.sas)"
echo "  • Output results (analysis_output.csv)"
echo ""
echo "Any change in inputs or code produces a different Merkle root → immediate detection"

