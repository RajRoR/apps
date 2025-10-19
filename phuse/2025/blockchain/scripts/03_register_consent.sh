#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

CONSENT=data/consent_SUBJ001_v2.json
HASH=$(python3 scripts/hash_sdtm.py json $CONSENT | awk -F= '/SHA256/ {print $2}')
CANON=$(python3 - <<EOF
import json,sys
print(json.dumps(json.load(open("$CONSENT")), separators=(',',':'), sort_keys=True))
EOF
)

# Fill payloadHash into the canonical JSON (for record completeness)
CONSENT_CANON=$(python3 - <<EOF
import json
obj = json.loads('''$CANON''')
obj["payloadHash"]="$HASH"
print(json.dumps(obj, separators=(',',':')))
EOF
)

# Escape the JSON for use in the chaincode argument
CONSENT_CANON_ESCAPED=$(echo "$CONSENT_CANON" | sed 's/"/\\"/g')

# Invoke via Org1 peer (Sponsor)
pushd "$FS/test-network" >/dev/null

# Satisfy envVar.sh expectations (it runs with set -u)
export VERBOSE=${VERBOSE:-false}
export OVERRIDE_ORG=${OVERRIDE_ORG:-""}
export USING_COUCHDB=${USING_COUCHDB:-false}
export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-test-network}
export CONTAINER_CLI=${CONTAINER_CLI:-docker}
export CONTAINER_CLI_COMPOSE=${CONTAINER_CLI_COMPOSE:-"docker compose"}
export DOCKER_SOCK=${DOCKER_SOCK:-/var/run/docker.sock}

. ./scripts/envVar.sh

setGlobals 1  # Org1 = Sponsor
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  -C clinicaltrial -n clinicalcc \
  --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  -c "{\"Args\":[\"RegisterConsent\",\"SUBJ001_v2\",\"$CONSENT_CANON_ESCAPED\",\"$HASH\"]}"
popd >/dev/null

echo -e "\033[0;32mConsent registered by the Sponsor.\033[0m HASH=\033[1;33m$HASH\033[0m"
