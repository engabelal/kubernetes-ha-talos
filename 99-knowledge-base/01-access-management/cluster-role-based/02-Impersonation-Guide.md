# Master Guide: Cluster Access & Impersonation

This guide connects two advanced concepts: **Cluster-Wide Access (ClusterRole)** and **Testing Permissions (Impersonation)**.

---

## Part 1: ClusterRole vs. ClusterRoleBinding

When you want to give permissions to the **Entire Cluster** (not just one specific namespace), you use a `ClusterRole`.

### 1. The Strategy
We want user `ahmedbelal` to be able to **SEE EVERYTHING** (all pods, all namespaces) but **TOUCH NOTHING**.

### 2. The Solution (Key Components)

#### A. The "What" (ClusterRole)
Defines the permissions globally.
```yaml
kind: ClusterRole
metadata:
  name: read-pods-ns-clusterrole
rules:
  - apiGroups: [""]
    resources: ["namespaces", "pods"]
    verbs: ["get", "list", "watch"] # Read-Only
```

#### B. The "Who & Where" (ClusterRoleBinding)
Connects the user to the role for the whole cluster.
```yaml
kind: ClusterRoleBinding
metadata:
  name: read-pods-ns-binding
subjects:
  - kind: User
    name: ahmedbelal
roleRef:
  kind: ClusterRole
  name: read-pods-ns-clusterrole
```

---

## Part 2: Understanding Impersonation (`--as`)

Impersonation is testing your new permissions properly. It answers the question: *"Does this actually work?"*

### 1. The "Identity Crisis" Error
If you run this command while logged in as `ahmedbelal`:
```bash
kubectl auth can-i list pods --as ahmedbelal
```
**Result:** `Error: User "ahmedbelal" cannot impersonate resource "users"`

**Why?**
You are asking to "pretend" to be yourself. Because you are a normal user (not root/admin), you don't have permission to "pretend". You only have permission to **BE**.

### 2. The Correct Way to Verify

#### Scenario A: You are logged in as Admin
You have the "Master Key". You can put on any mask you want to test others.
```bash
# 1. Switch to Admin
kubectl config use-context admin@cluster

# 2. Test the user's access
kubectl auth can-i list pods --as ahmedbelal
# Output: yes
```

#### Scenario B: You are logged in as Ahmed (The User)
You don't need a mask. Just check your own pockets.
```bash
# 1. Switch to User
kubectl config use-context ahmedbelal@cluster

# 2. Test DIRECTLY (No --as)
kubectl auth can-i list pods
# Output: yes
```

---

## Summary Cheat Sheet

| Task | Resource / Command |
| :--- | :--- |
| **Give Read-Only Global Access** | `ClusterRole` + `ClusterRoleBinding` |
| **Verify as Admin** | `kubectl auth can-i ... --as <user>` |
| **Verify as User** | `kubectl auth can-i ...` (No flag) |
