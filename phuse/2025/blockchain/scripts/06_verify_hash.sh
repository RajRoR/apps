#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

pushd "$FS/test-network" >/dev/null

# Set up Fabric binaries path
export PATH="${PWD}/../bin:$PATH"
export FABRIC_CFG_PATH="${PWD}/../config/"

# Satisfy envVar.sh expectations (it runs with set -u)
export VERBOSE=${VERBOSE:-false}
export OVERRIDE_ORG=${OVERRIDE_ORG:-""}
export USING_COUCHDB=${USING_COUCHDB:-false}
export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-test-network}
export CONTAINER_CLI=${CONTAINER_CLI:-docker}
export CONTAINER_CLI_COMPOSE=${CONTAINER_CLI_COMPOSE:-"docker compose"}
export DOCKER_SOCK=${DOCKER_SOCK:-/var/run/docker.sock}

. ./scripts/envVar.sh

# Auditor verifies dataset integrity
setGlobals 2

ANCHOR_JSON=$(peer chaincode query -C clinicaltrial -n clinicalcc -c '{"Args":["GetAnchor","ANCHOR_DM_1.0"]}')
popd >/dev/null

echo "$ANCHOR_JSON"

# Extract on-chain hash from JSON
ONCHAIN_HASH=$(echo "$ANCHOR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['sha256'])")

# Auditor recomputes hash locally
LOCAL_HASH=$(python3 scripts/hash_sdtm.py csv data/DM.csv | awk -F= '/SHA256/ {print $2}')

# Compare hashes
if [ "$ONCHAIN_HASH" == "$LOCAL_HASH" ]; then
  echo -e "\033[0;32mAuditor verified: dataset hash matches immutable ledger record\033[0m"
  echo -e "On-chain: \033[1;33m$ONCHAIN_HASH\033[0m"
  echo -e "Local:    \033[1;33m$LOCAL_HASH\033[0m"
else
  echo -e "\033[0;31m❌ VERIFICATION FAILED: Hash mismatch - tampering detected!\033[0m"
  echo -e "On-chain: \033[1;33m$ONCHAIN_HASH\033[0m"
  echo -e "Local:    \033[1;31m$LOCAL_HASH\033[0m"
  exit 1
fi
