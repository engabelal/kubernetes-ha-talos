#!/bin/bash

# 1. Add/Verify Gateway API CRDs (Already installed, but good for safety)
# using standard install for v1.2.0 which is compatible with EG v1.6
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

# 2. Install Envoy Gateway using Helm OCI
echo "Installing Envoy Gateway v1.6.1..."
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.6.1 \
  -n envoy-gateway-system \
  --create-namespace

echo "Waiting for encryption keys..."
kubectl wait --timeout=5m -n envoy-gateway-system job/envoy-gateway-create-keys --for=condition=Complete

echo "Done! Envoy Gateway v1.6.1 is running."
