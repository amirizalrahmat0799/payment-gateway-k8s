#!/usr/bin/env bash
# Applies the dev overlay and waits until everything is ready.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require kubectl

log "Applying k8s/overlays/dev"
kubectl apply -k "$ROOT/k8s/overlays/dev"

log "Waiting for PostgreSQL and Kafka"
kubectl -n "$NAMESPACE" rollout status statefulset/postgres --timeout=300s
kubectl -n "$NAMESPACE" rollout status statefulset/kafka --timeout=300s

log "Waiting for the applications"
for d in merchant-service tokenization-service payment-service settlement-service merchant-dashboard; do
  kubectl -n "$NAMESPACE" rollout status "deployment/$d" --timeout=420s
done

log "Deployed. Dashboard: http://localhost:8080"
kubectl -n "$NAMESPACE" get pods -o wide
