# 🔐 Cert-Manager & Self-Signed SSL

**Cert-Manager** automates the management and issuance of TLS certificates in Kubernetes.
Since we are in a private lab environment, we will use a **Self-Signed Issuer** to generate certificates locally.

## 🛠️ Installation

### 1. Install Cert-Manager
Apply the official manifest (v1.16.2).
```bash
kubectl apply -f cert-manager.yaml
```

**Verify Installation:**
Ensure all 3 pods (`cert-manager`, `cainjector`, `webhook`) are running in `cert-manager` namespace.
```bash
kubectl get pods -n cert-manager
```

### 2. Configure Issuer (Self-Signed)
We create a `ClusterIssuer` that simply signs certificates itself.
```bash
kubectl apply -f self-signed-issuer.yaml
```

## 🧪 Validation (HTTPS Test)

Let's update our `whoami` app to use HTTPS.

**1. Apply Secured Ingress:**
```bash
kubectl apply -f test-ingress-ssl.yaml
```

**2. Test with Curl (Insecure):**
Since it's self-signed, we use `-k` to ignore the warning.
```bash
curl -k https://whoami.172.16.16.101.sslip.io
```

**3. Test in Browser:**
Open `https://whoami.172.16.16.101.sslip.io`
You will see a **"Not Secure"** warning. Click **Advanced -> Proceed** to see the lock icon 🔒 (crossed out).
