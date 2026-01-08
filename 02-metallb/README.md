# ⚖️ MetalLB LoadBalancer (Networking)

In a typical Cloud environment (AWS, Google Cloud), when you request a `LoadBalancer`, the cloud provider gives you a public IP automatically.
**In a Private Lab (Bare Metal/VMs), that magic doesn't exist.** 🤔

**MetalLB** brings that magic to our lab! It acts as a standard network router implementation for Kubernetes.

---

## 🧠 How it Works: Layer 2 Mode (ARP)

We are using **Layer 2 Mode**. Here is what happens when you create a Service:

1.  **Request:** You create a Service `type: LoadBalancer`.
2.  **Assignment:** MetalLB's Controller assigns an IP (e.g., `172.16.16.101`) from the pool we gave it.
3.  **Announcement (The "Magic"):** The **Speaker Pods** (running on every worker) start shouting via **ARP** (Address Resolution Protocol):
    > *"Hey Network! Who has 172.16.16.101? I DO! Send traffic to this node!"* 📣
4.  **Traffic Flow:** Your router updates its ARP table and sends traffic for `.101` to that worker node.

```text
       User (Browser)
             │
             ▼
    [ Router / Switch ]
             │
    (ARP Request: Who has .101?)
             │
      ┌──────┴──────┐
      │             │
   [WK01]        [WK02] ◄── "I have .101!" (Speaker Pod)
```

---

## 🛠️ Configuration & Setup

### 1. Installation
We installed MetalLB `v0.15.3` (Native Manifests). It deploys:
*   **Controller:** Assigns IPs.
*   **Speakers:** DaemonSet (one per node) to talk to the network.

### 2. The IP Address Plan
We allocated a small chunk of our network specifically for Services:
*   **Network:** `172.16.16.0/24`
*   **Cluster VIP:** `172.16.16.100` (Reserved for API)
*   **MetalLB Pool:** `172.16.16.101` - `172.16.16.120` (For Apps)

### 3. IPAddressPool Config (`metallb-config.yaml`)
This tells MetalLB which IPs it owns.
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
spec:
  addresses:
  - 172.16.16.101-172.16.16.120
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
```
*The `L2Advertisement` is crucial; without it, MetalLB owns the IPs but won't "announce" them.*

---

## 🧪 Validation

### Infrastructure Check
Ensure all speakers are running (Status: `Running`). If a speaker is dead, that node cannot receive traffic.
```bash
kubectl get pods -n metallb-system -o wide
```

### Functional Check (Nginx)
We can deploy a temporary Nginx to see if it grabs an IP.
```bash
kubectl create deploy nginx --image=nginx
kubectl expose deploy nginx --port=80 --type=LoadBalancer
kubectl get svc nginx
```
*You should see `EXTERNAL-IP: 172.16.16.101` immediately.*

