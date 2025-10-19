#!/usr/bin/env bash
set -euo pipefail

# ---- locate fabric-samples and set Fabric envs ----
# Default to fabric-samples in project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS_DEFAULT="$PROJECT_ROOT/fabric-samples"
FS="${FABRIC_SAMPLES:-$FS_DEFAULT}"

if [ ! -d "$FS/test-network" ]; then
  echo "❌ fabric-samples not found at: $FS"
  echo "   Expected location: $PROJECT_ROOT/fabric-samples"
  echo "   Or set: export FABRIC_SAMPLES=\"/absolute/path/to/fabric-samples\""
  exit 1
fi

export PATH="$FS/bin:$PATH"
export FABRIC_CFG_PATH="$FS/config"
# ---------------------------------------------------

CONSENT="data/consent_withdrawn_SUBJ001_v2.json"
[ -f "$CONSENT" ] || { echo "❌ Missing $CONSENT"; exit 1; }

# 1) Canonicalize JSON & compute hash
HASH=$(python3 scripts/hash_sdtm.py json "$CONSENT" | awk -F= '/SHA256/ {print $2}')
CANON=$(python3 - <<'EOF' "$CONSENT"
import json,sys
p=sys.argv[1]
obj=json.load(open(p))
print(json.dumps(obj, separators=(',',':'), sort_keys=True))
EOF
)

# 2) Inject payloadHash
CONSENT_CANON=$(python3 - <<'EOF' "$HASH" "$CANON"
import json,sys
h=sys.argv[1]; canon=sys.argv[2]
obj=json.loads(canon)
obj["payloadHash"]=h
print(json.dumps(obj, separators=(',',':')))
EOF
)

# 3) Escape double quotes for embedding in the CLI JSON string
CONSENT_ESCAPED=$(echo "$CONSENT_CANON" | sed 's/"/\\"/g')

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
setGlobals 1  # Org1 = Sponsor

ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORG1_PEER_CA="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
ORG2_PEER_CA="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

# Invoke the UpdateConsent transaction
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C clinicaltrial -n clinicalcc \
  --peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_PEER_CA" \
  --peerAddresses localhost:9051 --tlsRootCertFiles "$ORG2_PEER_CA" \
  -c "{\"Args\":[\"UpdateConsent\",\"SUBJ001_v2\",\"$CONSENT_ESCAPED\",\"$HASH\"]}"

popd >/dev/null

echo -e "\033[0;32mConsent withdrawn by the Sponsor.\033[0m HASH=\033[1;33m$HASH\033[0m"
