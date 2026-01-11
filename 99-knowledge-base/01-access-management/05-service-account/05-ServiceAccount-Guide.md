# ServiceAccounts: Identity for Bots

While **Users** are for humans, **ServiceAccounts (SA)** are for machines (Pods, CI/CD, Controllers).

---

## 1. What did we create?

We created a simple "Bot" that has permission to **create pods** and **services** in the `default` namespace.

1.  **Identity:** `ServiceAccount` names `pod-creator-bot`.
2.  **Permissions:** `Role` named `pod-creator-role` (Can create pods/services).
3.  **Connection:** `RoleBinding` named `assign-bot-creator`.
4.  **Usage:** A Pod `bot-pod-example` that uses this identity.

---

## 2. Validation: How to test an SA?

You cannot "login" as a ServiceAccount easily (it uses tokens). But you can **Impersonate** it to check permissions!

The syntax is:
`system:serviceaccount:<namespace>:<service-account-name>`

### Test 1: Check if it can Create Pods (Should be YES)
```bash
kubectl auth can-i create pods \
  --as=system:serviceaccount:default:pod-creator-bot \
  -n default
# Output: yes
```

### Test 2: Check if it can Delete Secrets (Should be NO)
```bash
kubectl auth can-i delete secrets \
  --as=system:serviceaccount:default:pod-creator-bot \
  -n default
# Output: no
```

---

## 3. Why is this useful?

This is the foundation of **"Least Privilege"** for applications.
Instead of giving your Pod `admin` access, you give it an SA with **only** the permissions it needs (e.g., read secrets, write to database).

---

## 4. Advanced: How it works inside the Pod

How does the Pod actually **use** this permission?

1.  Kubernetes automatically mounts a **Token** at `/var/run/secrets/kubernetes.io/serviceaccount/token`.
2.  The application (Python script, helper tool, or `curl`) reads this token.
3.  It sends an HTTP request to the Kubernetes API Server with `Authorization: Bearer <TOKEN>`.

### Example: Creating a Pod using `curl` (Inside the Pod)

If you exec into the pod, you can try this:

```bash
# 1. Get the Token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# 2. Make the API Call to create a new Pod
curl -X POST https://kubernetes.default.svc/api/v1/namespaces/default/pods \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/json" \
  --cacert $CACERT \
  --data '{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "child-pod" },
    "spec": { "containers": [{ "name": "nginx", "image": "nginx" }] }
  }'
```
