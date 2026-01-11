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
