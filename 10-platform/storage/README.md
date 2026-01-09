# 🐂 Longhorn Distributed Storage

**Longhorn** is a lightweight, distributed block storage system for Kubernetes. It turns the local disk space of your nodes into redundant storage for your Pods.

## 🛠️ Installation

### 1. Add Repository
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

### 2. Install (Helm)
```bash
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.defaultDataPath="/var/lib/longhorn"
```

### 3. Verification
Check the UI to see the dashboard.
**Access:** `http://longhorn.172.16.16.101.sslip.io`

---

---

## 🧐 Deep Dive: The Talos vs. Longhorn Challenge

You might wonder: *"Why was this so hard? Why didn't it just work?"*
The answer lies in the **Philosophy of Talos Linux**.

### 1. The Conflict: "Safe" vs. "Powerful"
*   **Talos (The Vault):** Talos is designed to be **Minimal** and **Locked Down**. It forbids:
    *   Changing system files (Immutable).
    *   Installing packages (No `apt`, `yum`, or `apk`).
    *   Pods touching the host (Strict Security).
*   **Longhorn (The Builder):** Longhorn is a storage system. It needs to:
    *   Format physical disks (Requires **Root/Privileged** access).
    *   Use `iscsiadm` to map volumes (Requires **System Tools**).

### 2. Challenge #1: "Computer Says NO" (Pod Security)
**Problem:** When Longhorn tried to start, Talos's admission controller blocked it.
> *Error: `violates PodSecurity "baseline": privileged`*

**Why?**
Talos defaults to the `baseline` security standard, which bans "Privileged" containers. It prevents a hacked pod from taking over the node.

**The Fix:**
We manually told Kubernetes: *"Trust the `longhorn-system` namespace. Let it run as Root."*
```bash
kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce=privileged
```

### 3. Challenge #2: "Missing Tools" (iSCSI)
**Problem:** Longhorn crashed saying: `executable file not found in $PATH: iscsiadm`.

**Why?**
Most Linux distros (Ubuntu/CentOS) come with everything installed "just in case".
**Talos comes with NOTHING.** It doesn't have `iscsi-tools` pre-installed because 99% of web apps don't need them. This makes Talos smaller and safer.

**The Fix (The "Talos Way"):**
Since we can't run `apt-get install open-iscsi`, we had to **Replace the Operating System Image**.
We used the **Image Factory** to bake a custom Talos image that *includes* the `iscsi-tools` extension, and then upgraded the nodes to this new image.

---

## 🔧 Troubleshooting Steps (Summary)

### 1. Fix Security (Privileged Access)
```bash
kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce=privileged --overwrite
kubectl label namespace longhorn-system pod-security.kubernetes.io/audit=privileged --overwrite
kubectl label namespace longhorn-system pod-security.kubernetes.io/warn=privileged --overwrite
kubectl rollout restart daemonset longhorn-manager -n longhorn-system
```

### 2. Fix Dependencies (Install iSCSI Extension)
We upgraded the worker nodes to a custom image containing `siderolabs/iscsi-tools`.
```bash
# This forces the node to download the new OS image and reboot
talosctl upgrade --nodes 172.16.16.150 --image factory.talos.dev/installer/<ID>:v1.12.1
```
