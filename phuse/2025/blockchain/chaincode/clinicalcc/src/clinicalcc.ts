import { Context, Contract } from 'fabric-contract-api';

interface Consent {
  subjectId: string;
  version: string;
  status: 'active' | 'withdrawn';
  timestamp: string; // ISO8601
  payloadHash: string; // SHA-256 of JSON payload
}

interface DatasetAnchor {
  domain: string;       // e.g., DM
  version: string;      // e.g., 1.0
  fileName: string;     // e.g., DM.csv
  sha256: string;       // file hash
  createdAt: string;    // ISO8601
}

export class ClinicalCC extends Contract {

  async RegisterConsent(ctx: Context, key: string, consentJson: string, payloadHash: string) {
    const consent = JSON.parse(consentJson) as Consent;
    if (!consent.subjectId || !consent.version || !consent.status) {
      throw new Error('Invalid consent object');
    }
    
    // Check if consent with this exact key exists
    const exists = await this._exists(ctx, `CONSENT_${key}`);
    if (exists) {
      // Allow re-registration only if previous consent was withdrawn
      const existingBytes = await ctx.stub.getState(`CONSENT_${key}`);
      const existingConsent = JSON.parse(existingBytes.toString()) as Consent;
      if (existingConsent.status === 'active') {
        throw new Error(`Active consent already exists for key ${key}. Use UpdateConsent to modify.`);
      }
      // Allow overwriting withdrawn consent (re-consent scenario)
    }
    
    await ctx.stub.putState(`CONSENT_${key}`, Buffer.from(JSON.stringify(consent)));
    // Update index to point to latest consent version
    await ctx.stub.putState(`CONSENT_SUBJ_${consent.subjectId}`, Buffer.from(key));
    return { ok: true, key, payloadHash };
  }

  async UpdateConsent(ctx: Context, key: string, consentJson: string, payloadHash: string) {
    const exists = await this._exists(ctx, `CONSENT_${key}`);
    if (!exists) throw new Error(`Missing consent record ${key}`);
    const consent = JSON.parse(consentJson) as Consent;
    await ctx.stub.putState(`CONSENT_${key}`, Buffer.from(JSON.stringify(consent)));
    return { ok: true, key, payloadHash };
  }

  async AnchorDataset(ctx: Context, anchorKey: string, anchorJson: string) {
    // policy: require active consent before anchoring
    const anchor = JSON.parse(anchorJson) as DatasetAnchor;
    
    // Check if consent exists for the subject
    const subjKeyBytes = await ctx.stub.getState(`CONSENT_SUBJ_SUBJ-001`); // demo: single subject
    if (!subjKeyBytes || !subjKeyBytes.length) {
      throw new Error('No consent found for subject; anchoring rejected by policy');
    }
    
    // Get consent record
    const consentKey = subjKeyBytes.toString();
    const consentBytes = await ctx.stub.getState(`CONSENT_${consentKey}`);
    if (!consentBytes || !consentBytes.length) {
      throw new Error('Consent record not found; anchoring rejected by policy');
    }
    
    // Verify consent is active
    const consent = JSON.parse(consentBytes.toString()) as Consent;
    if (consent.status !== 'active') {
      throw new Error(`Consent status is '${consent.status}'; anchoring rejected by policy (requires 'active')`);
    }
    
    // All checks passed - anchor the dataset
    await ctx.stub.putState(`ANCHOR_${anchorKey}`, Buffer.from(JSON.stringify(anchor)));
    return { ok: true, anchorKey };
  }

  async GetConsent(ctx: Context, key: string) {
    const v = await ctx.stub.getState(`CONSENT_${key}`);
    if (!v || !v.length) throw new Error(`No consent ${key}`);
    return v.toString();
  }

  async GetAnchor(ctx: Context, anchorKey: string) {
    const v = await ctx.stub.getState(`ANCHOR_${anchorKey}`);
    if (!v || !v.length) throw new Error(`No anchor ${anchorKey}`);
    return v.toString();
  }

  private async _exists(ctx: Context, key: string) {
    const data = await ctx.stub.getState(key);
    return !!(data && data.length);
  }
}

export const contracts: any[] = [ClinicalCC];
