# Blockchain-Inspired Statistical Computing Environment (SCE)

A proof-of-concept demonstrating blockchain-inspired integrity principles for statistical computing in clinical trials, presented at PHUSE EU 2025.

**Paper:** DH03 - Blockchain for Secure and Transparent Clinical Trials

## Overview

This POC demonstrates how blockchain principles (immutability, cryptographic hashing, append-only records) can strengthen data integrity and audit trails in statistical computing environments **without requiring distributed consensus networks**.

### Key Concepts Demonstrated:

- **Content Addressing**: Every dataset identified by its cryptographic hash (SHA-256)
- **Immutable Anchoring**: Dataset fingerprints recorded on append-only ledger
- **Lineage Tracking**: Analysis runs linked to specific input/code/output versions
- **Merkle Trees**: Bundle-level verification with single root hash
- **Tamper Evidence**: Any modification immediately detectable through hash mismatch

## Architecture

### Network Participants
- **Statistical Computing Team (Org1)**: Anchors datasets, records analysis lineage
- **QC/Audit Team (Org2)**: Verifies data integrity and lineage completeness

### Channel
- `clinicaltrial` - Shared ledger for immutable audit records

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
- Launches peer nodes for Statistical and QC teams
- Creates the `clinicaltrial` channel

### Step 2: Deploy Chaincode

```bash
./scripts/02_deploy_chaincode.sh
```

**What it does:**
- Packages the TypeScript chaincode
- Installs on both organizations' peers
- Commits chaincode definition to the channel

### Step 3: Anchor DM Dataset

```bash
./scripts/03_anchor_dataset.sh
```

**What it does:**
- Computes SHA-256 hash of Demographics (DM) dataset
- Anchors hash on blockchain with metadata (domain, version, timestamp, creator)
- Creates immutable proof that dataset existed in this exact state

**Key concept:** Content addressing - the hash IS the dataset's identity.

### Step 4: Anchor AE Dataset

```bash
./scripts/04_anchor_sdtm.sh
```

**What it does:**
- Anchors Adverse Events (AE) dataset
- Demonstrates multiple dataset anchoring (building blocks for Merkle tree)

### Step 5: Record Analysis Lineage

```bash
./scripts/04_record_lineage.sh
```

**What it does:**
- Records an analysis run linking:
  - Input dataset (DM.csv) → identified by hash
  - Statistical program (analysis_program.sas) → hash of code
  - Output results (analysis_output.csv) → hash of outputs
- Computes Merkle root covering entire analysis bundle
- Creates cryptographic proof of reproducibility

**Important:** This demonstrates how every analysis becomes verifiable and traceable.

### Step 6: Verify Dataset Integrity

```bash
./scripts/05_verify_hash.sh
```

**What it does:**
- Auditor queries on-chain hash for DM dataset
- Recomputes hash from local DM.csv
- Compares hashes to verify data integrity

**Success case:** Hashes match → Data is authentic and unmodified

**Failure case:** Edit DM.csv (change any value), rerun script → Verification fails with red error!

### Step 7: Verify Analysis Lineage

```bash
./scripts/06_verify_lineage.sh
```

**What it does:**
- Retrieves complete lineage record for an analysis run
- Shows Merkle root linking inputs, code, and outputs
- Demonstrates cryptographic traceability of analytical results

## Project Structure

```
blockchain/
├── chaincode/clinicalcc/          # Smart contract (TypeScript)
│   ├── src/clinicalcc.ts          # Lineage & anchoring logic
│   ├── package.json               # Dependencies
│   └── tsconfig.json              # TypeScript config
├── scripts/                       # Automation scripts
│   ├── 01_up_network.sh          # Network startup
│   ├── 02_deploy_chaincode.sh    # Chaincode deployment
│   ├── 03_anchor_dataset.sh      # Anchor DM dataset
│   ├── 04_anchor_sdtm.sh         # Anchor AE dataset
│   ├── 04_record_lineage.sh      # Record analysis lineage
│   ├── 05_verify_hash.sh         # Hash verification
│   ├── 06_verify_lineage.sh      # Lineage verification
│   └── hash_sdtm.py              # Hash computation utility
├── data/                          # Sample data
│   ├── DM.csv                     # Demographics dataset
│   ├── AE.csv                     # Adverse Events dataset
│   ├── analysis_program.sas       # Statistical program
│   └── analysis_output.csv        # Analysis results
└── README.md
```

## Smart Contract Functions

### `AnchorDataset(anchorKey, anchorJson)`
Anchor a dataset hash on the ledger.
- **Caller:** Statistical Computing Team
- **Validation:** Checks for duplicate anchors
- **Creates:** Immutable dataset fingerprint

### `RecordLineage(lineageJson)`
Record complete analysis lineage with Merkle root.
- **Caller:** Statistical Computing Team
- **Validation:** Verifies all input datasets exist
- **Creates:** Cryptographic proof of reproducibility

### `GetAnchor(anchorKey)`
Query dataset anchor record.
- **Caller:** Any participant (Auditors, QC)
- **Returns:** Domain, version, hash, timestamp, creator

### `GetLineage(analysisId)`
Query analysis lineage record.
- **Caller:** Any participant
- **Returns:** Full lineage with inputs, program, outputs, Merkle root

### `VerifyHash(anchorKey, providedHash)`
Verify a dataset hash against on-chain record.
- **Caller:** Any participant
- **Returns:** Verification result with comparison

## Key Concepts Demonstrated

### 1. **Content Addressing (Hash-Based Identity)**
```
Dataset identity = SHA-256(file_content)
```
- Same content → Same hash (deterministic)
- Different content → Different hash (tamper evident)
- Hash becomes immutable version identifier

### 2. **Immutable Audit Trail**
```typescript
// Append-only ledger - no deletions, no modifications
await ctx.stub.putState(`ANCHOR_${key}`, data);
```
Every dataset anchor is permanent - audit history cannot be altered.

### 3. **Cryptographic Lineage**
```
Input Hash + Program Hash + Output Hash → Merkle Root
```
Single root hash proves entire analysis bundle integrity.

### 4. **Reproducibility Verification**
```
Re-run analysis → Compare new Merkle root with recorded root
Match → Reproducible
Mismatch → Non-reproducible (investigate!)
```

## Blockchain-Inspired Principles in SCE

| Blockchain Principle | What It Ensures | SCE Implementation | Benefit |
|---------------------|-----------------|-------------------|---------|
| **Append-only ledger** | Prevents silent overwrites | Immutable anchor records | Verifiable "who anchored what and when" |
| **Cryptographic hashes** | Detect tampering | SHA-256 for all artifacts | Immutable version identity |
| **Merkle tree** | Verifies complete bundle | Analysis-level root hash | One-click bundle validation |
| **Smart contracts** | Automate rules | Lineage validation checks | Built-in compliance |
| **Distributed consensus** | Shared trust | Multi-tenant SCE governance | Internal transparency |

## Testing Tampering Detection

**Demonstrate hash verification failure:**

1. Run the full workflow (scripts 01-05) successfully
2. Edit `data/DM.csv` - change any single character (e.g., age 53 → 54)
3. Run `./scripts/05_verify_hash.sh` again
4. **Result:** Verification fails with red error message showing hash mismatch

This demonstrates how even minor tampering is immediately detectable!

## Use Cases for Statistical Computing

1. **Regulatory Submissions:** Immutable proof of data provenance for FDA/EMA
2. **Reproducibility:** Cryptographic verification of exact analytical environment
3. **Audit Trails:** Complete lineage from raw data → programs → outputs
4. **Version Control:** Content-based versioning prevents silent overwrites
5. **QC Reviews:** Auditors verify analysis integrity without re-running programs

## Performance Benchmarks

SHA-256 hash computation performance:

| Dataset Size | Hash Time | Throughput |
|--------------|-----------|------------|
| 1 MB         | ~25 ms    | 40 MB/s    |
| 10 MB        | ~270 ms   | 37 MB/s    |
| 50 MB        | ~950 ms   | 52 MB/s    |
| 500 MB       | ~3.6 sec  | 185 MB/s   |

**Conclusion:** Hash computation is negligible compared to statistical analysis runtime.

Run `./scripts/test_hash_performance.sh` to benchmark on your system.

## Cleanup

To stop the network and clean up:

```bash
cd fabric-samples/test-network
./network.sh down
cd ../..
```

## Technical Details

### Hash Algorithm
- **SHA-256**: Cryptographically secure, 256-bit output
- **Deterministic**: Same input always produces same hash
- **Avalanche effect**: Single bit change completely changes hash

### Merkle Tree Construction
```
Merkle Root = hash(
  hash(Input Datasets) + 
  hash(Program Code) + 
  hash(Outputs)
)
```

### Storage Architecture
- **On-chain:** Hashes, metadata, lineage records (kilobytes)
- **Off-chain:** Full datasets, programs, outputs (megabytes/gigabytes)

## Alignment with Regulatory Requirements

This POC addresses:

- ✅ **21 CFR Part 11**: Electronic records and signatures with audit trails
- ✅ **ALCOA+**: Attributable, Legible, Contemporaneous, Original, Accurate, Complete, Consistent, Enduring, Available
- ✅ **ICH E6(R3)**: Data integrity and quality management
- ✅ **Computer Software Assurance (CSA)**: Risk-based validation and control

## Future Enhancements

- Multiple SDTM domains (VS, LB, EG) with Merkle tree aggregation
- Program version control integration (Git hash linking)
- Environment fingerprinting (container digests, package versions)
- Cross-system lineage (EDC → SDTM → Analysis → TLFs)
- Inspector dashboard for visual lineage graphs

## References

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [CDISC SDTM Standards](https://www.cdisc.org/standards/foundational/sdtm)
- [FDA 21 CFR Part 11](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/part-11-electronic-records-electronic-signatures-scope-and-application)
- [ICH E6(R3) GCP Guidelines](https://www.ich.org/)

## Contact

**Author:** Raj Kumar  
**Company:** Sycamore Informatics Inc.  
**Email:** raj.kumar@sycamoreinformatics.com  
**Website:** https://sycamoreinformatics.com/

Presented at PHUSE EU 2025

---

**Note:** This POC uses Hyperledger Fabric's test network for demonstration. The same integrity principles can be implemented within a single-organization SCE using simpler append-only databases, without distributed blockchain infrastructure.
