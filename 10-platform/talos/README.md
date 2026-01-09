# 🐧 Talos Linux Bootstrap

This module covers the initial installation and bootstrapping of the **Talos Linux** operating system across the 6-node cluster.

---

## 📋 Node Assignment Plan

| Hostname | IP Address | Type | Role |
| :--- | :--- | :--- | :--- |
| **cp01** | `172.16.16.147` | Control Plane | Etcd Leader / API |
| **cp02** | `172.16.16.148` | Control Plane | Etcd Follower |
| **cp03** | `172.16.16.149` | Control Plane | Etcd Follower |
| **wk01** | `172.16.16.150` | Worker | Data Plane |
| **wk02** | `172.16.16.151` | Worker | Data Plane |
| **wk03** | `172.16.16.152` | Worker | Data Plane |
| **VIP**  | `172.16.16.100` | Virtual IP | K8s API Entrypoint |

---

## 🚀 Bootstrap Process

### Step 1: Apply OS Configuration
Apply the YAML configurations to all nodes. These files define the network, disks, and cluster settings.

**Control Plane Nodes:**
```bash
talosctl apply-config --insecure --nodes 172.16.16.147 --file cp01.yaml
talosctl apply-config --insecure --nodes 172.16.16.148 --file cp02.yaml
talosctl apply-config --insecure --nodes 172.16.16.149 --file cp03.yaml
```

**Worker Nodes:**
```bash
talosctl apply-config --insecure --nodes 172.16.16.150 --file wk01.yaml
talosctl apply-config --insecure --nodes 172.16.16.151 --file wk02.yaml
talosctl apply-config --insecure --nodes 172.16.16.152 --file wk03.yaml
```

### Step 2: Initialize the Cluster
Run the bootstrap command on the **first** control plane node. This will initialize the `etcd` cluster and start the Kubernetes control plane.

```bash
# Set your target node
talosctl config endpoint 172.16.16.147
talosctl config node 172.16.16.147

# Execute Bootstrap
talosctl bootstrap
```

### Step 3: Retrieve Kubeconfig
Once the control plane is healthy, download the `kubeconfig` to manage the cluster via `kubectl`.

```bash
# This will generate a 'kubeconfig' file in the current directory
talosctl kubeconfig . --force

# Test access
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

---

## 🔍 Verification
- Verify that `kubectl get nodes` shows all 6 nodes as `Ready`.
- Verify that `talosctl health` shows all services are healthy.
- Ensure the VIP `172.16.16.100` responds to pings.
