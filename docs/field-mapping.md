# Field Mapping — "Creating a Relationship Binding" → Archon `did:cid`

Tom Jones' paper specifies two signed JOSE documents. Archon realizes both as
schema-bound Verifiable Credentials. The signing/encryption envelope the paper
enumerates as claims (message id, subject public key, signature, encryption) is
supplied **natively** by Archon issuance, so those items are intentionally *not*
modeled as schema properties.

## Consent to Create Binding Request → `relationship-binding-request`

| # | Paper field | Req. | Archon realization |
|---|-------------|------|--------------------|
| 1 | Identifier of the message | proto | `messageId` (optional) — Archon VC already carries a CID |
| 2 | Issuer (Audience / CSP) | M | `issuer` — provider `did:cid` (encryption target) |
| 3 | Subject (Grantor) | M | `subject` — **`did:cid` replaces the UUID** as durable anchor |
| 4 | Subject Role | M | `subjectRole` enum |
| 5 | Context (trust framework) | M | `context[]` — Archon **group** / trust-registry DID(s) |
| 6 | Subject Attributes | O | `subjectAttributes` (email/mobile, pseudonymous ok) |
| 7 | Permissions / contractual terms | M | `permissions[]` + `contractualTerms` |
| 8 | Device Statement | M (AAL2+) | `deviceStatement` |
| 9 | Identity Proof | M | `identityProof[]` ("None" allowed; DIDs of held VCs) |
| 10 | Purpose of Use | M (>L1) | `purposeOfUse` |
| 11 | ACR | O | `acr` |
| 12 | Issue Date | M | `issueDate` (epoch) |
| 13 | Expiration Date | O | `expirationDate` (epoch) — time-limits the relationship |
| 14 | Subject Public Key | M | **native** — DID document verification method |
| 15 | Signature | M | **native** — Archon credential proof |
| 16 | Encryption | M | **native** — issuance encrypts to the issuer DID |

## Consent Receipt with Binding (Entity Statement) → `binding-receipt`

| # | Paper field | Req. | Archon realization |
|---|-------------|------|--------------------|
| 1 | Binding Statement (response ref) | M | `requestRef` — DID of the request VC |
| 2 | Issuer (Organization) | M | `issuer` — provider `did:cid` (brand ok) |
| 3 | Role of Issuer | M | `issuerRole[]` (CSP / IdP / Data Controller) |
| 4 | Legal Name | O | `legalName` |
| 5 | Subject | M | `subject` — the relationship anchor DID |
| 6 | Claims | O | `claims[]` (granted permissions) |
| 7 | Issue Date | M | `issueDate` |
| 8 | Expiration Date | O | `expirationDate` |
| 9 | Authority Hints | O | `authorityHints[]` |
| 10 | Issuer Public Key | M | **native** — DID document |
| 11 | Signature | M | **native** — credential proof |
| 12 | Encryption | M | **native** — encrypted to subject DID |
| — | (Archon extension) shared info space | — | `sharedSpace` — Archon **vault** DID |
| — | (Archon extension) notification channel | — | `notificationChannel` — **dmail** address |

## Lifecycle / non-claim concerns the paper raises, handled by Archon primitives

| Paper concern | Archon primitive |
|---------------|------------------|
| Relationship ID, "DID attached to a resolver" | `did:cid` — the **default** anchor, not the alternate |
| "Deterministic audit trail / immutable ledger" | DID version history (`resolve-did --version`) |
| "Frozen when relationship ended" | `revoke-credential` / `revoke-did` |
| Shared information space the relationship owns | Archon **vault** |
| Owner can shut it down, data destroyed | `remove-vault-member` / revoke |
| Notification channel (GDPR/CCPR) | **dmail** |
| Context = trust authority (family → country) | Archon **group** / archon-trust-registry (TRQP) |
| Time-limited / short-lived augmenting relationships | credential `expirationDate` |

## Difference vs. our GenitriX ↔ flaxscrip edge

Our existing relationship binding is a **symmetric** pair of VCs (each party
issues the reciprocal edge). Tom's model is an **asymmetric handshake**
(subject *requests*, provider *receipts back*). Both produce the same
revocable, time-limited, audit-trailed edge. The demo here implements Tom's
asymmetric handshake directly so the artifacts line up 1:1 with his paper.
