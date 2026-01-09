# 🧪 High Availability (HA) Verification Guide

This guide describes how to verify that your cluster is functioning correctly when one Control Plane (CP) node is down (e.g., `cp01`).

## 1. Verify Kubernetes API (Kubectl)
Since we use a **VIP (Virtual IP)** at `172.16.16.100`, `kubectl` should continue working without changes, as the VIP typically floats to an active node (usually the leader).

```bash
# Check if the API is still responsive
kubectl get nodes

# Check if workloads are still running
kubectl get pods -A
```
*If this works, your Keepalived/VIP failover is successful.*

---

## 2. Verify Etcd Cluster Health
Talos Linux uses `etcd` for state. We need to query a **living node** (e.g., `cp02` IP: `172.16.16.148`) because the default config might point to the dead node (`cp01`).

### Check Membership and Health
```bash
# ❌ INCORRECT (Will fail if cp01 is down)
talosctl --talosconfig talosconfig etcd status

# ✅ CORRECT (Ask a healthy node, e.g., cp02)
talosctl --talosconfig talosconfig --nodes 172.16.16.148 etcd status
```

### Check Member List
```bash
talosctl --talosconfig talosconfig --nodes 172.16.16.148 etcd members
```
You should see 3 members. One might be marked as unreachable internally, or just the list persists.

---

## 3. Verify Talos API
You can check the dashboard or service list of a surviving node to ensure services are healthy.

```bash
# Check services on a healthy node
talosctl --talosconfig talosconfig --nodes 172.16.16.148 service

# Check dashboard (GUI)
talosctl --talosconfig talosconfig --nodes 172.16.16.148 dashboard
```

---

## 4. Troubleshooting
If `kubectl` hangs:
1. Ping the VIP: `ping 172.16.16.100`.
2. If VIP is down, check `kubeconfig` to see if it points to a specific node IP instead of the VIP.
