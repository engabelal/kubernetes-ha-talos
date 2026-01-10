# Understanding Kubernetes Contexts

In Kubernetes, your `kubeconfig` file isn't just a list of clusters; it's a collection of **Contexts**.

## 1. What is a Context?

Think of a **Context** as a **"Connection Profile"**. It answers three questions:
1.  **Where** are you connecting? (**Cluster**)
2.  **Who** are you connecting as? (**User/Auth**)
3.  **What** are you looking at by default? (**Namespace**)

$$
\text{Context} = \text{Cluster} + \text{User} + \text{Namespace (Default)}
$$

---

## 2. Real-World Scenario

Imagine you are a DevOps Engineer working on two environments:
*   **Production:** You have **Admin** access.
*   **Development:** You have **limited** access (View only) for testing.

You create two contexts in your file:

| Context Name | Cluster | User | Default Namespace | Description |
| :--- | :--- | :--- | :--- | :--- |
| `prod-admin` | `aws-eks-prod` | `admin-user` | `default` | "Full Admin Access" |
| `dev-tester` | `aws-eks-dev` | `ahmed-view` | `cloudycode-uat` | "I am Testing in UAT" |

---

## 3. The Commands Explained

### A. See your profiles (`get-contexts`)
Lists all available connection profiles saved on your machine.
```bash
kubectl config get-contexts
```
*   The valid asterisk `*` shows your **Active** context.

### B. Switch your profile (`use-context`)
This is the most common command. It **activates** a specific profile.
```bash
# Switch to Production Admin
kubectl config use-context prod-admin
# Now all commands (kubectl get pods) run on Production as Admin.

# Switch to Dev Testing
kubectl config use-context dev-tester
# Now all commands run on Dev as the limited user.
```

### C. Modify a profile (`set-context`)
This allows you to **edit** the properties of a context. A very common trick is setting a **Default Namespace** so you don't have to type `-n` every time.

**Example:** You are tired of typing `-n cloudycode-uat`.
```bash
# Update the CURRENT context to always look at 'cloudycode-uat'
kubectl config set-context --current --namespace=cloudycode-uat
```
Now `kubectl get pods` automatically lists pods in `cloudycode-uat`.

### D. Delete a profile (`delete-context`)
Removes a context from your list (does not delete the cluster, just your saved profile).
```bash
kubectl config delete-context old-cluster-context
```

---

## 4. `use-context` vs. `set-context` (The Confusion)

*   **`use-context`** = **SWITCH**. "Take me to this context." (Moving from Room A to Room B).
*   **`set-context`** = **EDIT**. "Change the furniture in this room." (Changing the default namespace or user of a specific context).

> **Pro Tip:** Install tools like `kubectx` and `kubens` to switch contexts and namespaces much faster than typing these long commands!
