#!/usr/bin/env bash
# Relationship Binding Ceremony on Archon did:cid
# Realizes Tom Jones' "Creating a Relationship Binding" two-message handshake.
#
# Actors:
#   SUBJECT  = the user (grantor)            e.g. flaxscrip
#   PROVIDER = the CSP / service / agent     e.g. GenitriX
#
# Prereqs: KM_REGISTRY pointing at the local node; both IDs already in the wallet.
#   export KM="npx @didcid/keymaster"
#   export KM_REGISTRY="hyperswarm"   # or local registry of flaxlap.local
set -euo pipefail

KM="${KM:-npx @didcid/keymaster}"
REG="${KM_REGISTRY:-hyperswarm}"
SUBJECT="${SUBJECT:-flaxscrip}"
PROVIDER="${PROVIDER:-GenitriX}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
NOW="$(date +%s)"
EXP="$((NOW + 60*60*24*365))"   # 1-year time-limited relationship

echo "== 0. Context: trust framework as an Archon group =="
$KM use-id "$PROVIDER"
CTX=$($KM create-group "rel-binding-context" --registry "$REG")
echo "  context group: $CTX"

echo "== 1. Register the two schemas (owned by PROVIDER as CSP) =="
REQ_SCHEMA=$($KM create-schema "$HERE/schemas/relationship-binding-request.schema.json" --registry "$REG")
RCP_SCHEMA=$($KM create-schema "$HERE/schemas/binding-receipt.schema.json" --registry "$REG")
$KM add-alias relationship-binding-request "$REQ_SCHEMA"
$KM add-alias binding-receipt "$RCP_SCHEMA"
echo "  request schema: $REQ_SCHEMA"
echo "  receipt schema: $RCP_SCHEMA"

echo "== 2. SUBJECT builds + issues the Consent to Create Binding Request =="
$KM use-id "$SUBJECT"
SUBJECT_DID=$($KM resolve-id | python3 -c 'import sys,json;print(json.load(sys.stdin)["didDocument"]["id"])')
PROVIDER_DID=$($KM resolve-did "$PROVIDER" | python3 -c 'import sys,json;print(json.load(sys.stdin)["didDocument"]["id"])')

# bind credential to schema, fill claims, then issue (signs + encrypts to PROVIDER)
$KM bind-credential "$REQ_SCHEMA" "$PROVIDER_DID" > /tmp/req_bound.json
python3 - /tmp/req_bound.json "$SUBJECT_DID" "$PROVIDER_DID" "$CTX" "$NOW" "$EXP" <<'PY' > /tmp/req.json
import json,sys
b=json.load(open(sys.argv[1])); s=b["credentialSubject"]
s.update({
  "issuer": sys.argv[3], "subject": sys.argv[2], "subjectRole": "self",
  "context": [sys.argv[4]],
  "permissions": [{"resource":"health-record","actions":["read"]}],
  "identityProof": ["None"],
  "purposeOfUse": "remote-attestation-aal2",
  "issueDate": int(sys.argv[5]), "expirationDate": int(sys.argv[6]),
})
json.dump(b, sys.stdout)
PY
REQUEST_VC=$($KM issue-credential /tmp/req.json --registry "$REG")
echo "  request VC: $REQUEST_VC"

echo "== 3. PROVIDER accepts, opens shared space + notification channel, issues the Binding Receipt =="
$KM use-id "$PROVIDER"
$KM accept-credential "$REQUEST_VC"
VAULT=$($KM create-vault --registry "$REG")          # the shared information space
$KM add-vault-member "$VAULT" "$SUBJECT_DID"
$KM bind-credential "$RCP_SCHEMA" "$SUBJECT_DID" > /tmp/rcp_bound.json
python3 - /tmp/rcp_bound.json "$REQUEST_VC" "$PROVIDER_DID" "$SUBJECT_DID" "$VAULT" "$NOW" "$EXP" <<'PY' > /tmp/rcp.json
import json,sys
b=json.load(open(sys.argv[1])); s=b["credentialSubject"]
s.update({
  "requestRef": sys.argv[2], "issuer": sys.argv[3], "issuerRole": ["CSP","DataController"],
  "subject": sys.argv[4], "claims": [{"resource":"health-record","actions":["read"]}],
  "sharedSpace": sys.argv[5],
  "issueDate": int(sys.argv[6]), "expirationDate": int(sys.argv[7]),
})
json.dump(b, sys.stdout)
PY
RECEIPT_VC=$($KM issue-credential /tmp/rcp.json --registry "$REG")
echo "  receipt VC (binding): $RECEIPT_VC"

echo "== 4. Relationship now exists as a verifiable, revocable edge =="
echo "  anchor (relationship DID) : $SUBJECT_DID  <->  $PROVIDER_DID"
echo "  shared space (vault)      : $VAULT"
echo "  request  : $REQUEST_VC"
echo "  receipt  : $RECEIPT_VC"

echo
echo "== 5. (manual) Lifecycle termination - subject shuts it down, data destroyed =="
echo "  $KM use-id $PROVIDER && $KM revoke-credential $RECEIPT_VC"
echo "  $KM remove-vault-member $VAULT $SUBJECT_DID   # destroys held data"
echo "  audit trail preserved in DID version history: $KM resolve-did-version $RECEIPT_VC <n>"
