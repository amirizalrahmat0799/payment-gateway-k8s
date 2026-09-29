#!/usr/bin/env bash
# Creates the kind cluster with ingress-nginx and metrics-server (needed by the HPA).
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require kind kubectl

if kind get clusters | grep -qx "$CLUSTER"; then
  log "Cluster '$CLUSTER' already exists"
else
  log "Creating kind cluster '$CLUSTER'"
  kind create cluster --config "$ROOT/kind/cluster.yaml"
fi

log "Installing ingress-nginx"
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
kubectl wait --namespace ingress-nginx --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller --timeout=180s

log "Installing metrics-server"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# kind's kubelets use self-signed certificates
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true
kubectl -n kube-system rollout status deployment/metrics-server --timeout=120s

log "Cluster ready"
kubectl get nodes -o wide
