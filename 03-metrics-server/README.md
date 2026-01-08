# 📊 Kubernetes Metrics Server

The **Metrics Server** collects resource usage data (CPU/RAM) from the Kubelets and exposes them via the `metrics.k8s.io` API. This is required for `kubectl top` and **Horizontal Pod Autoscalers (HPA)**.

## 🛠️ Installation

We use the official **v0.8.0** manifest, patched for Talos (Self-Signed Certs).

### 1. Apply Manifest
```bash
kubectl apply -f metrics-server.yaml
```

> **ℹ️ Note:** The included `metrics-server.yaml` has been patched with `--kubelet-insecure-tls`. This is necessary because Talos Kubelets use self-signed certificates, which the Metrics Server would otherwise reject.

### 2. Verify Installation
Check that the pod is running in `kube-system`.
```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

### 3. Test Functionality
Wait about **60 seconds**, then run:
```bash
kubectl top nodes
```

*Expected Output:*
```
NAME   CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
cp01   124m         6%     1340Mi          8%
wk01   45m          2%     780Mi           4%
...
```
