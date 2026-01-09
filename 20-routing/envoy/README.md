# 🛡️ Envoy Gateway (Kubernetes Gateway API)

This module implements the **Kubernetes Gateway API** using **Envoy Gateway v1.6**.

> [!TIP]
> Gateway API is the modern, extensible successor to the Ingress API. It provides more expressive routing, better role-based access, and is vendor-neutral.

---

## 📂 Directory Structure

| Folder | Purpose | Who Manages? |
| :--- | :--- | :--- |
| `01-system-setup/` | **One-time infrastructure:** GatewayClass, Gateway, TLS Certificate | 👨‍💼 **Admin** |
| `02-service-templates/` | **Reusable blueprints:** HTTPRoute templates for new services | 📋 Reference |

---

## 🏗️ Architecture: Shared Gateway Pattern

We use a **single shared Gateway** for all services. This is the recommended production pattern:

```
┌─────────────────────────────────────────────────────────────────┐
│                     ONE-TIME SETUP (Admin)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ GatewayClass │  │   Gateway    │  │ Wildcard Certificate │   │
│  │ (envoy-gw)   │──│ (Listener)   │──│ (*.102.sslip.io)     │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                           │                                      │
│                     172.16.16.102                                │
└───────────────────────────┼─────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  HTTPRoute   │   │  HTTPRoute   │   │  HTTPRoute   │
│  (App A)     │   │  (App B)     │   │  (App C)     │
└──────────────┘   └──────────────┘   └──────────────┘
   PER-SERVICE        PER-SERVICE        PER-SERVICE
   (Developer)        (Developer)        (Developer)
```

**Benefits:**
- ✅ **Cost Efficient:** Single LoadBalancer IP for all services
- ✅ **Centralized TLS:** One wildcard certificate covers everything
- ✅ **Developer Autonomy:** App teams only manage their HTTPRoute

---

## ⚙️ Part 1: One-Time Setup (Admin)

> [!IMPORTANT]
> This section is done **ONCE** when setting up the cluster. Developers skip this!

### Files in `01-system-setup/`

| # | File | Purpose |
|:---|:---|:---|
| 00 | `00-gatewayclass.yaml` | Registers Envoy as the Gateway controller |
| 01 | `00-install.sh` | Helm installation script |
| 02 | `01-gateway.yaml` | Creates the shared Gateway (gets IP from MetalLB) |
| 03 | `02-certificate.yaml` | **Wildcard TLS cert** for `*.172.16.16.102.sslip.io` |

### Installation Commands

```bash
# Step 1: Install Envoy Gateway controller
helm install envoy-gw oci://docker.io/envoyproxy/gateway-helm --version v1.6.1 \
  -n envoy-gateway-system \
  --create-namespace

# Step 2: Apply all system setup files
kubectl apply -f 20-routing/envoy/01-system-setup/

# Step 3: Verify Gateway has IP
kubectl get gateway -n default
# Expected: ADDRESS = 172.16.16.102, PROGRAMMED = True
```

### What Gets Created?

| Resource | Name | Purpose |
|:---|:---|:---|
| `GatewayClass` | `envoy-gw` | Tells K8s to use Envoy for Gateway resources |
| `Gateway` | `my-envoy-gateway` | Listens on port 80/443, accepts routes from ALL namespaces |
| `Certificate` | `envoy-wildcard-cert` | Wildcard TLS for `*.172.16.16.102.sslip.io` |
| `Secret` | `envoy-tls-secret` | Auto-created by cert-manager (contains the cert) |

---

## 📦 Part 2: Per-Service Setup (Developer)

> [!NOTE]
> This is what you do **for each new service**. No TLS configuration needed!

### What You Need to Create

For a new service called `nginx-belal`:

```
30-workloads/nginx-belal/
├── 00-namespace.yaml      # (Optional) Dedicated namespace
├── 01-deployment.yaml     # Deployment + Service
└── 02-httproute.yaml      # 👈 This is the only routing file you need!
```

### HTTPRoute Template

Copy from `02-service-templates/http-route.yaml` or use this:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: nginx-belal-route
  namespace: nginx-belal
spec:
  parentRefs:
    - name: my-envoy-gateway      # ✅ Points to shared Gateway
      namespace: envoy-gateway-system
  hostnames:
    - "belal.172.16.16.102.sslip.io"  # ✅ Your unique subdomain
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: nginx-belal-svc   # ✅ Your service name
          port: 80
```

### Apply Your Service

```bash
kubectl apply -f 30-workloads/nginx-belal/

# Test (HTTP)
curl http://belal.172.16.16.102.sslip.io

# Test (HTTPS) - Works automatically because of Wildcard cert!
curl -k https://belal.172.16.16.102.sslip.io
```

---

## 🔐 TLS: How It Works

### Ingress API (Old Way)
Each service needed:
- `annotations: cert-manager.io/cluster-issuer`
- `tls:` section with `secretName`
- Cert-manager creates a **new certificate per service**

### Gateway API (New Way)
Admin creates once:
- **Wildcard Certificate** (`*.172.16.16.102.sslip.io`)
- Gateway references this certificate in `tls.certificateRefs`

**TLS Termination Explained:**
```
User Browser                    Gateway                      Pod
    │                              │                          │
    │── HTTPS (encrypted) ────────▶│                          │
    │                              │── HTTP (plain) ─────────▶│
    │                              │                          │
    │◀───────── Response ──────────│◀────── Response ─────────│
```

The Gateway **terminates** (decrypts) HTTPS traffic:
- `tls.mode: Terminate` = Gateway handles SSL, backend receives plain HTTP
- `tls.mode: Passthrough` = Gateway forwards encrypted traffic, backend handles SSL

Developers:
- Just create HTTPRoute
- **No TLS configuration needed!**
- Wildcard cert covers all subdomains automatically

---

## 🆚 Quick Comparison: Adding a New Service

| Step | Ingress (Traefik) | Gateway API (Envoy) |
|:---|:---|:---|
| 1. Create Namespace | ✅ | ✅ |
| 2. Create Deployment | ✅ | ✅ |
| 3. Create Service | ✅ | ✅ |
| 4. Create Route | `Ingress` (with TLS config) | `HTTPRoute` (no TLS!) |
| 5. TLS Certificate | Auto-created per service | Uses existing Wildcard |

---

## 📚 Resources

- [Gateway API Docs](https://gateway-api.sigs.k8s.io/)
- [Envoy Gateway Docs](https://gateway.envoyproxy.io/)
- [Cert-Manager + Gateway API](https://cert-manager.io/docs/usage/gateway/)
