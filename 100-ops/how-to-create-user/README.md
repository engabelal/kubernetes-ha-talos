# 👤 How to Create a New User in Kubernetes

Kubernetes does **not** manage users natively. Instead, it relies on external authentication (like Certificates, OIDC, or Cloud IAM).

This guide walks through creating a user authenticated via **X.509 Client Certificates**.

---

## 🛠️ Step-by-Step Guide

### 1. Create a Private Key
Generate a private key for the user (`ahmedbelal`).
```bash
openssl genrsa -out ahmedbelal.key 4096
```

### 2. Create a Certificate Signing Request (CSR)
This is the most critical step. The `CN` (Common Name) and `O` (Organization) fields determine the User and Group identity in Kubernetes.

```bash
# CN = Username (ahmedbelal)
# O  = Group    (devops) - optional, useful for group permissions
openssl req -new -key ahmedbelal.key -out ahmedbelal.csr -subj "/CN=ahmedbelal/O=devops"
```

> [!IMPORTANT]
> **Authentication Logic:**
> Kubernetes identifies the user **solely** by the `CN` field in the valid certificate.
> If `CN=ahmedbelal`, Kubernetes says: *"Hello, user ahmedbelal"* and then checks RBAC rules for that name.

### 3. Submit CSR to Kubernetes
Encode the CSR content to Base64 (remove newlines!).

```bash
# MacOS / Linux
cat ahmedbelal.csr | base64 | tr -d '\n'
```

Create a `CertificateSigningRequest` object:
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ahmedbelal
spec:
  request: <BASE64_CSR_HERE>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
```
Apply it:
```bash
kubectl apply -f ahmedbelal-csr.yaml
```

### 4. Approve the Certificate
The cluster admin must explicitly approve this request.
```bash
kubectl certificate approve ahmedbelal
```

### 5. Extract the Signed Certificate
Retrieve the signed certificate from the API server.
```bash
kubectl get csr ahmedbelal -o jsonpath='{.status.certificate}' | base64 -d > ahmedbelal.crt
```

### 6. Create Kubeconfig
Embed the cluster details and your new keys into a kubeconfig file.

> [!TIP]
> You need the **Cluster CA** (`ca.crt`) to verify the server properly.
> Extract it from your existing config if needed:
> `kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt`

```bash
# 1. Set Cluster Details
kubectl config set-cluster talos-cluster \
  --server=https://172.16.16.100:6443 \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --kubeconfig=ahmedbelal.kubeconfig

# 2. Set User Credentials
kubectl config set-credentials ahmedbelal \
  --client-certificate=ahmedbelal.crt \
  --client-key=ahmedbelal.key \
  --embed-certs=true \
  --kubeconfig=ahmedbelal.kubeconfig

# 3. Create Context (Link Cluster + User)
kubectl config set-context ahmedbelal-context \
  --cluster=talos-cluster \
  --user=ahmedbelal \
  --kubeconfig=ahmedbelal.kubeconfig

# 4. Set Current Context
kubectl config use-context ahmedbelal-context --kubeconfig=ahmedbelal.kubeconfig
```

---

## 🚀 How to Use the New Kubeconfig

Now that you have `ahmedbelal.kubeconfig`, you have 3 ways to use it.

### Method 1: The `--kubeconfig` Flag (Temporary)
Add the flag to every command. Good for testing.
```bash
kubectl get pods --kubeconfig=ahmedbelal.kubeconfig
```

### Method 2: Environment Variable (Session-based)
Export the variable for your current terminal session.
```bash
export KUBECONFIG=./ahmedbelal.kubeconfig

# Now all commands use this config automatically
kubectl get pods
```

### Method 3: Merge with Main Config (Permanent)
Import this user into your main `~/.kube/config` to switch easily.

```bash
# Takes entries from ahmedbelal.kubeconfig and merges them into ~/.kube/config
KUBECONFIG=~/.kube/config:./ahmedbelal.kubeconfig kubectl config view --flatten > ~/.kube/merged_config

# Replace old config
mv ~/.kube/merged_config ~/.kube/config

# Switch context anytime
kubectl config use-context ahmedbelal-context
```

---

## 🛡️ Step 7: Grant Permissions (RBAC)

At this point, the user is **Authenticated** but **Not Authorized**.
Trying to list pods will result in `Forbidden`. You must bind the user to a Role.

### Option A: Cluster Admin (Superuser)
```bash
kubectl create clusterrolebinding ahmedbelal-admin \
  --clusterrole=cluster-admin \
  --user=ahmedbelal
```

### Option B: Restricted Access (Example: View Only in 'default')
```bash
kubectl create rolebinding ahmedbelal-view \
  --clusterrole=view \
  --user=ahmedbelal \
  --namespace=default
```
