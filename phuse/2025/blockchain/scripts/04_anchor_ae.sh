#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

FILE=data/AE.csv
HASH=$(python3 scripts/hash_sdtm.py csv $FILE | awk -F= '/SHA256/ {print $2}')
ANCHOR_JSON=$(cat <<JSON
{"domain":"AE","version":"1.0","fileName":"AE.csv","sha256":"$HASH","createdAt":"2025-10-18T12:05:00Z","creator":"DataManager"}
JSON
)

# Escape the JSON for use in the chaincode argument
ANCHOR_JSON_ESCAPED=$(echo "$ANCHOR_JSON" | sed 's/"/\\"/g')

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

setGlobals 2  # Org2 = QC Team
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  -C clinicaltrial -n clinicalcc \
  --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  -c "{\"Args\":[\"AnchorDataset\",\"ANCHOR_AE_1.0\",\"$ANCHOR_JSON_ESCAPED\"]}"
popd >/dev/null

echo -e "\033[0;32mAE dataset anchored.\033[0m HASH=\033[1;33m$HASH\033[0m"
