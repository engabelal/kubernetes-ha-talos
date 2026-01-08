# 🚦 Traefik Ingress Controller

**Traefik** is a modern HTTP reverse proxy and load balancer. In Kubernetes, it acts as the **Ingress Controller**, routing external traffic (HTTP/HTTPS) to your internal Services.

## 🧠 Core Concept: Usage vs LoadBalancer

A **LoadBalancer** (MetalLB) gives you an IP.
An **Ingress** (Traefik) gives you **Routes** (Domains).

Instead of giving every app a public IP (expensive!), we give **Traefik** the SINGLE public IP (`172.16.16.101`), and it routes traffic based on the "Host" header.

```text
       User Request
[ http://whoami.172... ]
           │
           ▼
    [ MetalLB VIP ]  <-- 172.16.16.101
           │
           ▼
     [ Traefik ]     <-- "Oh, you want 'whoami'? Okay!"
     /          \
  [Whoami]    [Nginx]
```

---

## 🛠️ Installation (Helm)

### 1. Add Repository
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

### 2. Install Traefik
We use a custom `values.yaml` to set it as the **Default Ingress Class**.
```bash
helm install traefik traefik/traefik \
  --namespace kube-system \
  --values values.yaml
```

**Key Configuration:**
*   `type: LoadBalancer`: Asks MetalLB for an IP.
*   `ingressClass: traefik`: Registers itself as a controller.

### 3. Verify Installation
Check that Traefik has an **EXTERNAL-IP** (assigned by MetalLB).
```bash
kubectl get svc -n kube-system traefik
```
*Output: `EXTERNAL-IP: 172.16.16.101`*

---

## 🪄 Magic DNS (sslip.io)

Validating Ingress used to require editing `/etc/hosts`. No more!
**sslip.io** is a "Magic DNS" service. It maps any sub-domain containing an IP *back* to that IP.

*   `app.172.16.16.101.sslip.io` -> `172.16.16.101`
*   `blog.172.16.16.101.sslip.io` -> `172.16.16.101`

**Why?**
This allows us to instantly have "Real Domains" for testing SSL and Routing without buying a domain name or configuring a local DNS server.

---

## 🧪 Validation

**1. Apply Test App:**
```bash
kubectl apply -f test-ingress.yaml
```

**2. Access via Curl:**
```bash
curl http://whoami.172.16.16.101.sslip.io
```

**3. Browser:**
Open `http://whoami.172.16.16.101.sslip.io` to see the "Whoami" page.
