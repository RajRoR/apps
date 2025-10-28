#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

# Simulate an analysis run
ANALYSIS_ID="ANALYSIS_001"
PROGRAM_FILE="data/analysis_program.sas"
OUTPUT_FILE="data/analysis_output.csv"

# Compute hashes
PROGRAM_HASH=$(python3 scripts/hash_sdtm.py csv "$PROGRAM_FILE" | awk -F= '/SHA256/ {print $2}')
OUTPUT_HASH=$(python3 scripts/hash_sdtm.py csv "$OUTPUT_FILE" | awk -F= '/SHA256/ {print $2}')

# Compute Merkle root (simplified: hash of concatenated hashes)
DM_HASH=$(python3 scripts/hash_sdtm.py csv data/DM.csv | awk -F= '/SHA256/ {print $2}')
MERKLE_INPUT="$DM_HASH$PROGRAM_HASH$OUTPUT_HASH"
MERKLE_ROOT=$(echo -n "$MERKLE_INPUT" | shasum -a 256 | awk '{print $1}')

LINEAGE_JSON=$(cat <<JSON
{"analysisId":"$ANALYSIS_ID","inputDatasets":["ANCHOR_DM_1.0"],"programHash":"$PROGRAM_HASH","outputHash":"$OUTPUT_HASH","merkleRoot":"$MERKLE_ROOT","timestamp":"2025-10-18T14:30:00Z","analyst":"StatisticalProgrammer"}
JSON
)

# Escape the JSON
LINEAGE_JSON_ESCAPED=$(echo "$LINEAGE_JSON" | sed 's/"/\\"/g')

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

setGlobals 1  # Org1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  -C clinicaltrial -n clinicalcc \
  --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  -c "{\"Args\":[\"RecordLineage\",\"$LINEAGE_JSON_ESCAPED\"]}"
popd >/dev/null

echo -e "\033[0;32mAnalysis lineage recorded.\033[0m Merkle Root=\033[1;33m$MERKLE_ROOT\033[0m"

