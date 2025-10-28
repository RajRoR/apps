import { Context, Contract } from 'fabric-contract-api';

interface DatasetAnchor {
  domain: string;       // e.g., DM, AE, LB
  version: string;      // e.g., 1.0
  fileName: string;     // e.g., DM.csv
  sha256: string;       // file hash
  createdAt: string;    // ISO8601
  creator: string;      // who anchored it (Sponsor/CRO)
}

interface AnalysisLineage {
  analysisId: string;      // unique analysis run identifier
  inputDatasets: string[]; // array of dataset anchor keys
  programHash: string;     // hash of statistical program
  outputHash: string;      // hash of output dataset
  merkleRoot: string;      // Merkle root of entire bundle
  timestamp: string;       // ISO8601
  analyst: string;         // who ran the analysis
}

export class ClinicalCC extends Contract {

  async AnchorDataset(ctx: Context, anchorKey: string, anchorJson: string) {
    const anchor = JSON.parse(anchorJson) as DatasetAnchor;
    
    // Validate required fields
    if (!anchor.domain || !anchor.sha256 || !anchor.fileName) {
      throw new Error('Invalid dataset anchor: missing required fields');
    }
    
    // Check if anchor already exists
    const exists = await this._exists(ctx, `ANCHOR_${anchorKey}`);
    if (exists) {
      throw new Error(`Dataset anchor already exists for key ${anchorKey}`);
    }
    
    // Store the anchor
    await ctx.stub.putState(`ANCHOR_${anchorKey}`, Buffer.from(JSON.stringify(anchor)));
    
    // Create index by domain for easy lookup
    await ctx.stub.putState(`DOMAIN_${anchor.domain}`, Buffer.from(anchorKey));
    
    return { ok: true, anchorKey, sha256: anchor.sha256 };
  }

  async RecordLineage(ctx: Context, lineageJson: string) {
    const lineage = JSON.parse(lineageJson) as AnalysisLineage;
    
    // Validate required fields
    if (!lineage.analysisId || !lineage.merkleRoot || !lineage.programHash) {
      throw new Error('Invalid lineage record: missing required fields');
    }
    
    // Verify that input datasets exist
    for (const inputKey of lineage.inputDatasets) {
      const exists = await this._exists(ctx, `ANCHOR_${inputKey}`);
      if (!exists) {
        throw new Error(`Input dataset not found: ${inputKey}`);
      }
    }
    
    // Store lineage record
    await ctx.stub.putState(`LINEAGE_${lineage.analysisId}`, Buffer.from(JSON.stringify(lineage)));
    
    return { ok: true, analysisId: lineage.analysisId, merkleRoot: lineage.merkleRoot };
  }

  async GetAnchor(ctx: Context, anchorKey: string) {
    const v = await ctx.stub.getState(`ANCHOR_${anchorKey}`);
    if (!v || !v.length) throw new Error(`No anchor ${anchorKey}`);
    return v.toString();
  }

  async GetLineage(ctx: Context, analysisId: string) {
    const v = await ctx.stub.getState(`LINEAGE_${analysisId}`);
    if (!v || !v.length) throw new Error(`No lineage record for ${analysisId}`);
    return v.toString();
  }

  async VerifyHash(ctx: Context, anchorKey: string, providedHash: string) {
    const anchorBytes = await ctx.stub.getState(`ANCHOR_${anchorKey}`);
    if (!anchorBytes || !anchorBytes.length) {
      return { verified: false, message: `Anchor ${anchorKey} not found` };
    }
    
    const anchor = JSON.parse(anchorBytes.toString()) as DatasetAnchor;
    const verified = anchor.sha256 === providedHash;
    
    return {
      verified,
      onChainHash: anchor.sha256,
      providedHash,
      message: verified ? 'Hash verified - data integrity confirmed' : 'Hash mismatch - tampering detected'
    };
  }

  private async _exists(ctx: Context, key: string) {
    const data = await ctx.stub.getState(key);
    return !!(data && data.length);
  }
}

export const contracts: any[] = [ClinicalCC];
