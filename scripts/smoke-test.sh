#!/usr/bin/env bash
# End-to-end check through the Ingress: onboard a merchant, tokenize a card, charge it,
# replay the same idempotency key, refund, and confirm the event reached the ledger via Kafka.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require curl

BASE="${BASE_URL:-http://localhost:8080}"
RUN_ID="$(date +%s)"

json() { sed -n "s/.*\"$1\":\"\{0,1\}\([^\",}]*\).*/\1/p"; }

call() { # method path [body] [extra curl args...]
  local method="$1" path="$2" body="${3:-}"; shift 3 || shift $#
  curl -sS --fail-with-body -X "$method" "$BASE$path" -H 'Content-Type: application/json' \
       ${body:+-d "$body"} "$@"
}

log "Onboarding a merchant"
MERCHANT=$(call POST /merchant-api/api/v1/merchants \
  "{\"name\":\"Smoke Test $RUN_ID\",\"email\":\"smoke-$RUN_ID@example.com\",\"feeBps\":250}")
API_KEY=$(echo "$MERCHANT" | json apiKey)
MERCHANT_ID=$(echo "$MERCHANT" | json id)
[ -n "$API_KEY" ] || fail "no API key in response: $MERCHANT"

log "Tokenizing a test card"
TOKEN=$(call POST /token-api/api/v1/tokens '{"pan":"4242424242424242","expiryMonth":12,"expiryYear":2035}' | json token)
[[ "$TOKEN" == tok_* ]] || fail "unexpected token: $TOKEN"

BODY="{\"amount\":15000,\"currency\":\"MYR\",\"cardToken\":\"$TOKEN\",\"capture\":true}"

log "Charging RM 150.00"
PAYMENT=$(call POST /payment-api/api/v1/payments "$BODY" -H "X-Api-Key: $API_KEY" -H "Idempotency-Key: smoke-$RUN_ID")
PAYMENT_ID=$(echo "$PAYMENT" | json id)
STATUS=$(echo "$PAYMENT" | json status)
[ "$STATUS" = "CAPTURED" ] || fail "expected CAPTURED, got $STATUS"

log "Replaying the same Idempotency-Key"
REPLAY_ID=$(call POST /payment-api/api/v1/payments "$BODY" -H "X-Api-Key: $API_KEY" -H "Idempotency-Key: smoke-$RUN_ID" | json id)
[ "$REPLAY_ID" = "$PAYMENT_ID" ] || fail "idempotency broken: $REPLAY_ID != $PAYMENT_ID"

log "Refunding RM 20.00"
call POST "/payment-api/api/v1/payments/$PAYMENT_ID/refunds" '{"amount":2000}' -H "X-Api-Key: $API_KEY" >/dev/null

log "Waiting for the ledger (outbox -> Kafka -> settlement-service)"
for _ in $(seq 1 30); do
  LEDGER=$(call GET "/settlement-api/api/v1/ledger?merchantId=$MERCHANT_ID")
  COUNT=$(echo "$LEDGER" | { grep -o '"entryType"' || true; } | wc -l | tr -d ' ')
  [ "$COUNT" -ge 2 ] && break
  sleep 2
done
[ "${COUNT:-0}" -ge 2 ] || fail "expected 2 ledger entries (capture + refund), found ${COUNT:-0}"

log "Smoke test passed: payment $PAYMENT_ID captured, replayed, refunded and recorded in the ledger"
