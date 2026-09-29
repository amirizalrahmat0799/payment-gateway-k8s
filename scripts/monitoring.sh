#!/usr/bin/env bash
# Installs Prometheus + Grafana (kube-prometheus-stack) plus the gateway's ServiceMonitor,
# alert rules and Grafana dashboard.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require helm kubectl

log "Installing kube-prometheus-stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values "$ROOT/k8s/monitoring/kube-prometheus-stack-values.yaml" \
  --wait --timeout 10m

log "Applying ServiceMonitor, alerts and dashboard"
kubectl apply -k "$ROOT/k8s/monitoring"

cat <<MSG

Grafana:     kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
             http://localhost:3000  (admin / admin) > Dashboards > Payment Gateway
Prometheus:  kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090
MSG
