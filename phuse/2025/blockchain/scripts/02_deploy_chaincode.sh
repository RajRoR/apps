#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

pushd "$FS/test-network" >/dev/null

CC_NAME=clinicalcc
CC_PATH=../../chaincode/clinicalcc
CC_LANG=typescript
CHANNEL=clinicaltrial

./network.sh deployCC -ccn $CC_NAME -ccp $CC_PATH -ccl $CC_LANG -c $CHANNEL

popd >/dev/null
echo -e "\033[0;32mChaincode deployed: $CC_NAME on $CHANNEL\033[0m"
