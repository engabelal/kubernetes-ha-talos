# 🐂 Longhorn Distributed Storage

**Longhorn** is a lightweight, distributed block storage system for Kubernetes. It turns the local disk space of your nodes into redundant storage for your Pods.

## 🛠️ Installation

### 1. Add Repository
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

### 2. Install Longhorn (Latest)
We install it in the `longhorn-system` namespace.
```bash
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace
```

### 3. Verify Components
Wait for all pods to be `Running` (this may take 2-3 minutes).
```bash
kubectl get pods -n longhorn-system -w
```

## 📊 Access Longhorn UI
Longhorn provides a dashboard to manage volumes and backups. We can expose it via **Ingress**.

**Apply the UI Ingress:**
```bash
kubectl apply -f longhorn-ingress.yaml
```

**Access:**
👉 `http://longhorn.172.16.16.101.sslip.io`
