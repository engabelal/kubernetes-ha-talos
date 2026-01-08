# ⚖️ MetalLB LoadBalancer Setup

This directory contains the configuration for **MetalLB**, which provides a "Physical" IP address for your Kubernetes Services (LoadBalancer type).

## 1. Install MetalLB
We use the official native manifests (v0.15.3).

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
```

**Verify Installation:**
Ensure all pods are running (speakers on all nodes, controller on control plane).
```bash
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

## 2. Configure IP Pool
We have allocated the range `172.16.16.101` - `172.16.16.120`.

**File:** `metallb-config.yaml`
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.16.16.101-172.16.16.120
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
```

**Apply Configuration:**
```bash
kubectl apply -f metallb-config.yaml
```

## 3. 🧪 Validation (Check Health)

### A. Infrastructure Validation (No Deployments)
Check if MetalLB itself is healthy and ready to announce IPs.

**1. Check Pods Status:**
Ensure `controller` (1 pod) and `speaker` (one per node) are `Running`.
```bash
kubectl get pods -n metallb-system -o wide
```

**2. Check Config is Loaded:**
Verify that your Pool and Advertisement are accepted.
```bash
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system
```

**3. Check Speaker Logs (ARP):**
See if the speakers are successfully broadcasting.
```bash
# Pick one speaker pod name from step 1
kubectl logs -n metallb-system -l app=metallb --tail=50
```
*You should see messages like `announcing...` whenever an IP is assigned.*

### B. Functional Validation (Optional Test)
Let's deploy a small Nginx server to prove MetalLB is handing out IPs.

**1. Deploy Nginx & Expose it:**
```bash
kubectl create deploy nginx --image=nginx
kubectl expose deploy nginx --port=80 --type=LoadBalancer
```

**2. Check the IP:**
```bash
kubectl get svc nginx
```
*Look for `EXTERNAL-IP`. It should be `172.16.16.101` (or the next available in pool).*

**3. Test Connectivity:**
```bash
curl 172.16.16.101
```
*You should see the "Welcome to nginx!" HTML.*

**4. Cleanup:**
```bash
kubectl delete svc nginx
kubectl delete deploy nginx
```

## 🌐 How Ingress Works (Traefik / Nginx)
When you install an Ingress Controller:
1. It requests a `Service` of type `LoadBalancer`.
2. MetalLB sees this request.
3. MetalLB assigns an IP (e.g., `172.16.16.101`) to that Service.
4. You configure your DNS (`*.talos.lab`) to point to that IP.
