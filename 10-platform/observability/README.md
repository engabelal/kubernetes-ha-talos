# 📊 Observability - Metrics Server

Metrics Server provides **resource metrics** (CPU/Memory) for Kubernetes built-in autoscaling and monitoring.

## 🎯 Purpose

- Enables `kubectl top nodes` and `kubectl top pods`
- Required for Horizontal Pod Autoscaler (HPA)
- Lightweight alternative to full monitoring stacks

## 📦 Installation

```bash
kubectl apply -f metrics-server.yaml

# Verify
kubectl top nodes
```

## 📁 Files

| File | Purpose |
|:---|:---|
| `metrics-server.yaml` | Deployment with TLS skip for Talos |

> [!NOTE]
> The manifest includes `--kubelet-insecure-tls` flag required for Talos Linux.
