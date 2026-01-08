# 👽 KubeInvaders (Gamified Chaos Engineering)

**KubeInvaders** is a gamified chaos engineering tool for Kubernetes. It allows you to stress-test your cluster by shooting aliens (Pods) in a Space Invaders-style interface.

## 🚀 Overview

- **Target Namespace**: `default` (Aliens = Pods in default namespace)
- **Access URL**: `http://kubeinvaders.172.16.16.102.sslip.io`
- **Gateway**: Envoy Gateway (Cross-Namespace Routing)

## 🛠️ Deployment

Apply the manifests in this directory order:

```bash
# 1. Create Namespace & RBAC (Cluster Permissions)
kubectl apply -f 01-rbac.yaml

# 2. Deploy Application & Service
kubectl apply -f 02-deployment.yaml

# 3. Expose via Envoy Gateway
kubectl apply -f 03-httproute.yaml
```

## 🎮 How to Play

1. Open **[http://kubeinvaders.172.16.16.102.sslip.io](http://kubeinvaders.172.16.16.102.sslip.io)** in your browser.
2. You will see the Pods in the `default` namespace represented as aliens.
3. **Press Space** to shoot! 🔫
4. When an alien is hit, the corresponding Kubernetes Pod is **deleted** functionality verified by `ClusterRole`.

> ⚠️ **Warning**: This tool actively deletes pods. Do not run this against critical production workloads unless you intend to test their resilience.
