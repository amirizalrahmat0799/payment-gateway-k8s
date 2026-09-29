#!/usr/bin/env bash
# Builds the five application images from the sibling repos and loads them into kind
# (no registry needed). Rebuild + reload after code changes, then run deploy.sh again.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require docker kind

[ -d "$GATEWAY_DIR" ]   || fail "payment-gateway-sim not found at $GATEWAY_DIR (set GATEWAY_DIR)"
[ -d "$DASHBOARD_DIR" ] || fail "merchant-dashboard not found at $DASHBOARD_DIR (set DASHBOARD_DIR)"

for module in merchant-service payment-service tokenization-service settlement-service; do
  log "Building pgs/$module:local"
  docker build --build-arg MODULE="$module" -t "pgs/$module:local" "$GATEWAY_DIR"
done

log "Building pgs/merchant-dashboard:local"
docker build -t pgs/merchant-dashboard:local "$DASHBOARD_DIR"

log "Loading images into kind"
kind load docker-image --name "$CLUSTER" \
  pgs/merchant-service:local pgs/payment-service:local pgs/tokenization-service:local \
  pgs/settlement-service:local pgs/merchant-dashboard:local
