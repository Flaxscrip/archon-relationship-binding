# archon-relationship-binding

A working Archon `did:cid` realization of Tom Jones' **"Creating a Relationship
Binding"** — the two-message consent handshake that produces a durable,
revocable, time-limited relationship between a subject and a service provider.

Built as a reference demo for Tom's paper, reusing the relationship-credential
pattern already in use for the flaxscrip ↔ GenitriX edge.

## Layout

- `schemas/relationship-binding-request.schema.json` — the **Consent to Create
  Binding Request** (Tom's 16 fields).
- `schemas/binding-receipt.schema.json` — the **Consent Receipt with Binding /
  Entity Statement** (Tom's 12 fields + Archon vault/dmail extensions).
- `scripts/run-demo.sh` — end-to-end ceremony: schemas → request VC → receipt
  VC → shared vault → revocation/termination.
- `docs/field-mapping.md` — every paper field → its Archon realization.
- `docs/analysis-for-tom.md` — one-page analysis penned by GenitriX, shareable.

## The mapping in one line

Tom names a DID as the *alternate* relationship anchor and worries about its
immutable ledger; Archon makes the DID the *default* anchor and turns that
ledger into the audit trail his own lifecycle requirements ask for. Revocation,
the shared information space (vault), the notification channel (dmail), and the
trust context (group) are all native primitives rather than things to build.

## Run

```bash
export KM="npx @didcid/keymaster"
export KM_REGISTRY="hyperswarm"      # or the local flaxlap.local registry
export SUBJECT="flaxscrip"           # grantor
export PROVIDER="GenitriX"           # CSP / service / agent
./scripts/run-demo.sh
```

Requires both IDs present in the keymaster wallet and the wallet unlocked.
