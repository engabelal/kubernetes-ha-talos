# 🔐 Cert-Manager & TLS Certificates

**Cert-Manager** automates TLS certificate management in Kubernetes. It watches for Certificate resources and automatically issues, renews, and stores certificates as Secrets.

---

## 🏗️ Architecture: How Cert-Manager Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SELF-SIGNED (Development/Lab)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐              │
│  │ ClusterIssuer│      │ Certificate  │      │   Secret     │              │
│  │ (selfsigned) │─────▶│ (your-cert)  │─────▶│ (your-tls)   │              │
│  └──────────────┘      └──────────────┘      └──────────────┘              │
│         │                     │                     │                       │
│         │              Cert-Manager           Auto-Created!                 │
│         │              generates cert         (No manual Secret needed)     │
│         ▼                                                                   │
│  ┌──────────────┐                                                          │
│  │    LOCAL     │  ← No external connection needed                         │
│  │   SIGNING    │  ← Perfect for development/testing                       │
│  └──────────────┘  ← ⚠️ Browser shows "Not Trusted" warning               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         LET'S ENCRYPT (Production)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐              │
│  │ ClusterIssuer│      │ Certificate  │      │   Secret     │              │
│  │ (letsencrypt)│─────▶│ (your-cert)  │─────▶│ (your-tls)   │              │
│  └──────────────┘      └──────────────┘      └──────────────┘              │
│         │                     │                     │                       │
│         │              Cert-Manager           Auto-Created!                 │
│         │              requests cert                                        │
│         ▼                                                                   │
│  ┌──────────────┐                                                          │
│  │ ACME Server  │  ← Connects to Let's Encrypt API                         │
│  │ (Internet)   │  ← Validates domain ownership (HTTP-01 or DNS-01)        │
│  └──────────────┘  ← ✅ Browser shows "Trusted" green lock                 │
│                                                                             │
│  Requirements:                                                              │
│  - Public IP accessible from internet                                       │
│  - Real domain name (not sslip.io)                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Certificate Lifecycle

```
You Create:                     Cert-Manager Creates:
┌──────────────┐                ┌──────────────┐
│ Certificate  │  ───────────▶  │   Secret     │
│   (YAML)     │    Automatic   │ (kubernetes  │
│              │                │  .io/tls)    │
└──────────────┘                └──────────────┘
                                     │
                                     ▼
                               Contains:
                               - tls.crt (certificate)
                               - tls.key (private key)
                               - ca.crt  (CA certificate)
```

> [!IMPORTANT]
> You **never** need to create `kind: Secret` for TLS manually!
> Cert-Manager automatically creates and manages it.

---

## 📂 Files

| # | File | Purpose |
|:---|:---|:---|
| 00 | `00-cert-manager.yaml` | Install cert-manager controller |
| 01 | `01-self-signed-issuer.yaml` | ClusterIssuer for self-signed certs |

---

## 🛠️ Installation

### Step 1: Install Cert-Manager

```bash
kubectl apply -f 00-cert-manager.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=60s
```

**Components Installed:**
- `cert-manager`: Main controller
- `webhook`: Validates Certificate resources
- `cainjector`: Injects CA bundles into resources

### Step 2: Create Self-Signed Issuer

```bash
kubectl apply -f 01-self-signed-issuer.yaml
```

---

## 🔐 Creating a Certificate

### For Ingress (Traefik):
Add annotation to your Ingress - cert-manager handles the rest!

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "selfsigned-issuer"  # 👈 Magic annotation
spec:
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls-secret  # 👈 Cert-Manager creates this Secret
```

### For Gateway API (Envoy):
Create a Certificate resource explicitly:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-cert
spec:
  secretName: my-tls-secret  # 👈 Cert-Manager creates this Secret
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  dnsNames:
    - "*.example.com"
```

---

## 🔍 Useful Commands

```bash
# List all certificates
kubectl get certificates -A

# Check certificate details
kubectl describe certificate <name> -n <namespace>

# List TLS secrets
kubectl get secrets -A | grep "kubernetes.io/tls"

# View certificate expiry
kubectl get certificate <name> -o jsonpath='{.status.notAfter}'
```

---

## 🆚 Self-Signed vs Let's Encrypt

| Feature | Self-Signed | Let's Encrypt |
|:---|:---|:---|
| **Browser Trust** | ❌ Warning | ✅ Trusted |
| **Internet Required** | No | Yes |
| **Real Domain Needed** | No | Yes |
| **Use Case** | Dev/Lab | Production |
| **Cost** | Free | Free |

---

## 📚 Resources

- [Cert-Manager Docs](https://cert-manager.io/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
