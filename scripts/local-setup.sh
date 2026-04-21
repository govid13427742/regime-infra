#!/usr/bin/env bash
set -euo pipefail

echo "=== Regime Platform — Local Setup ==="

if command -v kind &>/dev/null; then
    TOOL="kind"
elif command -v minikube &>/dev/null; then
    TOOL="minikube"
else
    echo "ERROR: Neither 'kind' nor 'minikube' found."
    echo "  brew install kind       # recommended"
    echo "  brew install minikube"
    exit 1
fi

echo "Using: $TOOL"

if [ "$TOOL" = "kind" ]; then
    kind create cluster --name regime-dev --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
EOF
    for svc in regime-platform regime-market-data regime-feature-engine \
               regime-detection-core regime-backtesting regime-visualization; do
        kind load docker-image "$svc:latest" --name regime-dev 2>/dev/null || true
    done
else
    minikube start --memory=4096 --cpus=2 --profile=regime-dev
fi

echo ""
echo "Deploying services..."
kubectl apply -k k8s/overlays/local/
kubectl -n regime rollout status deployment --timeout=120s

echo ""
echo "=== Local cluster ready ==="
echo "Gateway: http://localhost:30080"
kubectl -n regime get pods
