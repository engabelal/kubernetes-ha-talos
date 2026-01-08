# 🔦 Headlamp Dashboard

Headlamp is an easy-to-use, versatile, and extensible Kubernetes dashboard.

## 🛠️ Installation (Helm)

We install Headlamp into `kube-system` using the official Helm chart.

### 1. Add Repository
```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update
```

### 2. Install
```bash
helm install my-headlamp headlamp/headlamp --namespace kube-system
```

### 3. Apply Configuration
Apply the Ingress and ServiceAccount (for admin token):
```bash
kubectl apply -f 07-dashboard-headlamp/ingress.yaml
kubectl apply -f 07-dashboard-headlamp/service-account.yaml
```

## 🔑 Access & Login

### 1. Dashboard URL
- **URL:** `https://headlamp.172.16.16.101.sslip.io`

### 2. Get Access Token
To log in, use the token from the `headlamp-admin` ServiceAccount:

```bash
kubectl -n kube-system get secret headlamp-admin-token -o go-template='{{.data.token | base64decode}}' && echo
```
Copy the long string starting with `eyJ...` and paste it into the Headlamp login screen.
