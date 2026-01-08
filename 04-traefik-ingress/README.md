# 🚦 Traefik Ingress Controller

**Traefik** is a modern HTTP reverse proxy and load balancer. In Kubernetes, it acts as the **Ingress Controller**, routing external traffic (HTTP/HTTPS) to your internal Services.

## 🔗 Integration with MetalLB
When installed, Traefik creates a Service of type `LoadBalancer`. **MetalLB** detects this and assigns it an IP from the pool (e.g., `172.16.16.101`).

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

### 3. Verify Installation
Check that Traefik has an **EXTERNAL-IP** (assigned by MetalLB).

```bash
kubectl get svc -n kube-system traefik
```
*Output Check:*
```
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
traefik   LoadBalancer   10.96.x.x       172.16.16.101   80:3xxxx/TCP, 443:3xxxx/TCP
```

### 🧪 Validation: Magic DNS (sslip.io) 🪄

**Why sslip.io?**
Validating Ingress usually requires editing your local `/etc/hosts` file to map a domain (like `whoami.local`) to the LoadBalancer IP. This is tedious.
**sslip.io** solves this by acting as a dynamic DNS service. Any domain ending in `.IP.sslip.io` automatically resolves to that `IP`.

**Example:**
`whoami.172.16.16.101.sslip.io`  ➡️ resolves to ➡️  `172.16.16.101`

**Steps:**
1.  **Apply Test Manifest:**
    ```bash
    kubectl apply -f test-ingress.yaml
    ```
2.  **Access directly:**
    ```bash
    curl http://whoami.172.16.16.101.sslip.io
    ```
*Or open `http://whoami.172.16.16.101.sslip.io` in your browser.*
