#!/usr/bin/env bash
set -euo pipefail

# Locate fabric-samples relative to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FS="${FABRIC_SAMPLES:-$PROJECT_ROOT/fabric-samples}"

pushd "$FS/test-network" >/dev/null

# Bring up CA + peers + orderer
# Org1 = Statistical Computing Team
# Org2 = QC/Audit Team
# Channel: clinicaltrial
./network.sh down 2>/dev/null || true
./network.sh up createChannel -ca -c clinicaltrial

popd >/dev/null
echo -e "\033[0;32mNetwork up with channel 'clinicaltrial' (Org1=Stats Team, Org2=QC Team)\033[0m"
