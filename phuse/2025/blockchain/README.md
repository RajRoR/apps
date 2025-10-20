# Clinical Trial Blockchain POC

A proof-of-concept demonstrating blockchain technology for clinical trial data integrity and consent management, presented at PHUSE EU 2025.

## Overview

This POC demonstrates how blockchain can address critical challenges in clinical trials:
- **Immutable audit trails** for regulatory compliance
- **Data integrity verification** using cryptographic hashes
- **Consent management** with policy enforcement
- **Multi-party trust** between Sponsor, CRO, and Regulators

## Architecture

### Network Participants
- **Sponsor (Org1)**: Pharmaceutical company managing the trial
- **CRO (Org2)**: Contract Research Organization collecting data
- **Regulator**: Read-only observer verifying data integrity

### Channel
- `clinicaltrial` - Private channel for trial data anchoring

## Prerequisites

- Docker & Docker Compose
- Node.js (v16+) & npm
- Python 3.x
- Hyperledger Fabric v2.5+

## Setup

### 1. Clone Hyperledger Fabric Samples

   ```bash
# Download and install Fabric samples, binaries, and Docker images
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- 2.5.4 1.5.7
mv fabric-samples ./
```

Alternatively, you can clone directly:

```bash
git clone --branch release-2.5 https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh | bash -s -- 2.5.4 1.5.7
cd ..
```

### 2. Install Chaincode Dependencies

```bash
cd chaincode/clinicalcc
npm install
cd ../..
```

## Demo Workflow

### Step 1: Start the Network

```bash
./scripts/01_up_network.sh
```

**What it does:**
- Starts Certificate Authorities (CAs)
- Launches peer nodes for Sponsor and CRO
- Creates the `clinicaltrial` channel

### Step 2: Deploy Chaincode

```bash
./scripts/02_deploy_chaincode.sh
```

**What it does:**
- Packages the TypeScript chaincode
- Installs on both organizations' peers
- Commits chaincode definition to the channel

### Step 3: Register Informed Consent

```bash
./scripts/03_register_consent.sh
```

**What it does:**
- Computes SHA-256 hash of consent document
- Sponsor registers consent on blockchain
- Creates immutable consent record

**Key concept:** No data can be anchored without active consent!

### Step 4: Anchor SDTM Dataset

```bash
./scripts/04_anchor_sdtm.sh
```

**What it does:**
- CRO computes hash of Demographics (DM) dataset
- Anchors hash on blockchain with metadata
- Smart contract validates active consent exists

**Important:** Only the hash is stored on-chain, not the actual data (privacy preservation).

### Step 5: Verify Data Integrity

```bash
./scripts/05_verify_hash.sh
```

**What it does:**
- Regulator queries on-chain hash
- Recomputes hash from received DM.csv
- Compares hashes to verify data integrity

**Success case:** Hashes match → Data is authentic and unmodified

**Failure case:** Edit DM.csv (change any value), rerun script → Verification fails!

### Step 6: Withdraw Consent

```bash
./scripts/06_withdraw_consent.sh
```

**What it does:**
- Updates consent status to "withdrawn"
- Blockchain enforces policy: no new data can be anchored
- Demonstrates GDPR "right to be forgotten" compliance

## Project Structure

```
blockchain/
├── chaincode/clinicalcc/          # Smart contract (TypeScript)
│   ├── src/clinicalcc.ts          # Contract logic
│   ├── package.json               # Dependencies
│   └── tsconfig.json              # TypeScript config
├── scripts/                       # Automation scripts
│   ├── 01_up_network.sh           # Network startup
│   ├── 02_deploy_chaincode.sh     # Chaincode deployment
│   ├── 03_register_consent.sh     # Consent registration
│   ├── 04_anchor_sdtm.sh          # Data anchoring
│   ├── 05_verify_hash.sh          # Hash verification
│   ├── 06_withdraw_consent.sh     # Consent withdrawal
│   ├── hash_sdtm.py               # Hash computation utility
│   └── test_hash_performance.sh   # Performance benchmarking
├── data/                          # Sample data
│   ├── DM.csv                     # Demographics SDTM dataset
│   ├── consent_SUBJ001_v2.json    # Active consent
│   └── consent_withdrawn_SUBJ001_v2.json
├── diagrams/                      # Interactive diagrams (HTML/SVG)
│   ├── architecture-diagram.html           # 4-layer architecture (color)
│   ├── architecture-diagram-bw.html        # 4-layer architecture (B&W)
│   ├── consent-management-diagram.html     # Consent governance (color)
│   ├── consent-management-diagram-bw.html  # Consent governance (B&W)
│   ├── sdtm-integration-diagram.html       # SDTM anchoring (color)
│   ├── sdtm-integration-diagram-bw.html    # SDTM anchoring (B&W)
│   ├── reference-implementation-diagram.html    # Network deployment (color)
│   ├── reference-implementation-diagram-bw.html # Network deployment (B&W)
│   ├── performance-graphs.html             # Performance analysis (color)
│   └── performance-graphs-bw.html          # Performance analysis (B&W)
└── README.md
```

## Smart Contract Functions

### `RegisterConsent(key, consentJson, payloadHash)`
Register new informed consent on blockchain.
- **Caller:** Sponsor
- **Validation:** Ensures consent doesn't already exist

### `UpdateConsent(key, consentJson, payloadHash)`
Update existing consent (e.g., withdrawal).
- **Caller:** Sponsor
- **Validation:** Consent must exist

### `AnchorDataset(anchorKey, anchorJson)`
Anchor SDTM dataset hash on blockchain.
- **Caller:** CRO
- **Policy:** Requires active consent, otherwise rejected

### `GetConsent(key)`
Query consent record.
- **Caller:** Any participant
- **Returns:** Full consent JSON

### `GetAnchor(anchorKey)`
Query anchored dataset metadata.
- **Caller:** Any participant (including Regulator)
- **Returns:** Domain, version, hash, timestamp

## Key Concepts Demonstrated

### 1. **Data Integrity (Tamper Evidence)**
- Cryptographic hashes (SHA-256) provide fingerprint of datasets
- Any modification changes the hash → tampering detected
- Immutable blockchain provides trusted timestamp

### 2. **Smart Contract Policy Enforcement**
```typescript
if (consent.status !== 'active') {
  throw new Error('Consent not active; anchoring rejected by policy');
}
```
Business rules enforced by code, not manual processes.

### 3. **Privacy Preservation**
- Only hashes stored on-chain, not raw data
- Complies with HIPAA/GDPR
- Full datasets transmitted off-chain via traditional channels

### 4. **Multi-Party Trust**
- No single party controls the ledger
- Cryptographic consensus ensures data integrity
- Regulators gain independent verification capability

## Use Cases for Clinical Trials

1. **Regulatory Audits:** Immutable audit trail for 21 CFR Part 11 compliance
2. **Data Provenance:** Prove when data was collected and by whom
3. **Consent Management:** Blockchain-enforced consent policies
4. **Protocol Deviations:** Timestamped, tamper-proof deviation records
5. **Data Transfers:** Verify data integrity during sponsor-to-regulator submissions

## Testing Tampering Detection

**Demonstrate hash verification failure:**

1. Run the full workflow (scripts 01-05) successfully
2. Edit `data/DM.csv` - change any single character (e.g., age 53 → 54)
3. Run `./scripts/05_verify_hash.sh` again
4. **Result:** Verification fails with red error message showing hash mismatch

This demonstrates how even minor tampering is immediately detectable!

## Interactive Diagrams

The `diagrams/` folder contains publication-ready interactive HTML diagrams for papers and presentations.

### Available Diagrams

1. **Architecture Diagram** - Four-layer blockchain system architecture
   - `architecture-diagram.html` - Color version (presentations)
   - `architecture-diagram-bw.html` - B&W version (academic papers)

2. **Consent Management** - Patient-centric governance and consent lifecycle
   - `consent-management-diagram.html` - Color version
   - `consent-management-diagram-bw.html` - B&W version

3. **SDTM Integration** - Dataset anchoring with Merkle trees
   - `sdtm-integration-diagram.html` - Color version
   - `sdtm-integration-diagram-bw.html` - B&W version

4. **Reference Implementation** - Complete network deployment
   - `reference-implementation-diagram.html` - Color version
   - `reference-implementation-diagram-bw.html` - B&W version

5. **Performance Analysis** - Blockchain verification scalability
   - `performance-graphs.html` - Color version with interactive charts
   - `performance-graphs-bw.html` - B&W version with formal captions

### How to Use Diagrams

**For Presentations:**
```bash
# Open colored versions in browser
open diagrams/architecture-diagram.html
open diagrams/consent-management-diagram.html
open diagrams/performance-graphs.html
```

**For Academic Papers:**
```bash
# Open B&W versions (grayscale optimized)
open diagrams/architecture-diagram-bw.html
open diagrams/consent-management-diagram-bw.html
open diagrams/performance-graphs-bw.html
```

**Export Options:**
- Click "📥 Export PDF" to save as PDF
- Click "📊 Export SVG" to save as scalable vector graphics
- Press `Ctrl/Cmd + P` to print or save as PDF
- Use "🎨 Switch to Color" or "⚫ Switch to B&W" buttons to toggle versions

**For LaTeX Papers:**
Export SVG or high-resolution PNG and include in your document:
```latex
\begin{figure}[t]
\centering
\includegraphics[width=\columnwidth]{diagrams/figure-1.pdf}
\caption{Four-layer blockchain architecture for clinical trials.}
\label{fig:architecture}
\end{figure}
```

All diagrams are optimized for:
- ✅ IEEE/ACM conference papers (2-column format)
- ✅ PowerPoint/Keynote slides (16:9 aspect ratio)
- ✅ Poster presentations (high-resolution export)
- ✅ Technical documentation (SVG scalability)

## Cleanup

To stop the network and clean up:

```bash
cd fabric-samples/test-network
./network.sh down
cd ../..
```

## Technical Details

### Hash Algorithm
- **SHA-256**: Cryptographically secure, collision-resistant
- **Canonicalization**: JSON sorted and minified before hashing for consistency

### Consensus
- Hyperledger Fabric's ordering service ensures all parties agree on transaction order
- Smart contract endorsement policy requires approval from both Sponsor and CRO

### Storage
- **On-chain:** Hashes, metadata, consent status (kilobytes)
- **Off-chain:** Full datasets, images, source documents (megabytes/gigabytes)

## Future Enhancements

- Multi-subject consent management
- Multiple SDTM domains (AE, LB, VS, etc.)
- Integration with EDC systems (Medidata Rave, Oracle Clinical One)
- Smart contract access control (role-based permissions)
- Query by subject ID, study site, date range

## References

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [CDISC SDTM Standards](https://www.cdisc.org/standards/foundational/sdtm)
- [FDA 21 CFR Part 11](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/part-11-electronic-records-electronic-signatures-scope-and-application)
- [PHUSE EU 2025](https://www.phuse.eu/)

## License

This is a proof-of-concept for educational and demonstration purposes.

## Contact

Presented at PHUSE EU 2025 - Blockchain for Clinical Trials Technical Paper

---

**Note:** This POC uses Hyperledger Fabric's test network for demonstration. Production deployments would require proper infrastructure, security hardening, and compliance validation.

