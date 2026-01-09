# ⚖️ MetalLB - Bare Metal Load Balancer

MetalLB provides **LoadBalancer** service type support for bare-metal Kubernetes clusters.

## 🎯 Purpose

In cloud environments, `type: LoadBalancer` gets a public IP automatically. On bare-metal, MetalLB fills this gap by announcing IPs via ARP (Layer 2).

## 📦 Installation

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml

# Wait for pods
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Apply IP Pool config
kubectl apply -f metallb/metallb-config.yaml
```

## 🌐 IP Pool Configuration

| Pool Name | Range | Usage |
|:---|:---|:---|
| `main-pool` | `172.16.16.100-120` | VIP + Ingress + Services |

**Key IPs:**
- `.100` → Control Plane VIP
- `.101` → Traefik (Legacy Ingress)
- `.102` → Envoy (Gateway API)

## 📁 Files

| File | Purpose |
|:---|:---|
| `metallb/metallb-config.yaml` | IP pool and L2 advertisement |
