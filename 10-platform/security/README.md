# 🔐 Cert-Manager & Self-Signed SSL

**Cert-Manager** creates a "Certificate Authority" (CA) inside your Kubernetes cluster. It watches Ingress resources and automatically issues certificates to secure them (HTTPS).

## 🧠 Core Concept: The "Chain of Trust"

1.  **Issuer:** The entity that signs the certificates. We created a **Self-Signed Issuer**, meaning "I vouch for myself".
2.  **Certificate:** The digital ID card for your website (`whoami...`).
3.  **Browser Trust:** Browsers (Chrome/Safari) trust strict list of global authorities (Google, DigiCert). They **do not** trust your local Self-Signed issuer by default.

> **Note:** This is why you see the `Not Secure` warning. The encryption is real (AES-256), but the *Trust* is missing. In production, we use **Let's Encrypt** (ACME) which *is* trusted.

---

## 🛠️ Installation

### 1. Install Cert-Manager
Apply the official manifest (v1.16.2).
```bash
kubectl apply -f cert-manager.yaml
```

**Components:**
*   `cert-manager`: The controller.
*   `webhook`: Validates resources (Important!).
*   `cainjector`: Injects CA bundles.

### 2. Configure Issuer (Self-Signed)
We create a `ClusterIssuer` (Global Issuer) that simply signs certificates itself.
```bash
kubectl apply -f self-signed-issuer.yaml
```

---

## 🧪 Validation (HTTPS Test)

Let's update our `whoami` app to use HTTPS.

**1. Apply Secured Ingress:**
```bash
kubectl apply -f test-ingress-ssl.yaml
```
*This asks Cert-Manager: "Please give me a cert for `whoami.172.16.16.101.sslip.io`!"*

**2. Verify Certificate:**
```bash
kubectl get certificates
kubectl get secrets | grep tls
```

**3. Test with Curl (Insecure):**
Since it's self-signed, we use `-k` to ignore the trust warning.
```bash
curl -k https://whoami.172.16.16.101.sslip.io
```
