# 🦅 Kubernetes HA on Talos Linux

Welcome to the **Ultimate Kubernetes High Availability Cluster** lab!
This project demonstrates a production-grade, fully automated Kubernetes cluster built on **Talos Linux** (IP-OS), designed for resilience, security, and modern GitOps practices.

---

## 🌟 Features & Capabilities

| Feature | Description | Status |
| :--- | :--- | :--- |
| **👑 HA Control Plane** | 3 Nodes with a Floating VIP (`100`) for zero-downtime API access. | ✅ Active |
| **🔒 Immutable OS** | **Talos Linux**: Read-only file system, API-driven, and highly secure. | ✅ Active |
| **⚖️ Load Balancing** | **MetalLB** provides physical IPs (Layer 2) to Services. | ✅ Active |
| **🚦 Ingress Controller** | **Traefik** routing HTTP/HTTPS traffic with automatic IP assignment. | ✅ Active |
| **🪄 Magic DNS** | **sslip.io** mapping (`*.101.sslip.io`) for instant domain resolution. | ✅ Active |
| **🔐 TLS/SSL** | **Cert-Manager** issuing Self-Signed certificates for secure HTTPS. | ✅ Active |
| **📦 Distributed Storage**| **Longhorn** providing replicated persistent volumes (Block Storage). | ✅ Active |
| **📊 Observability** | **Metrics Server** for real-time resource tracking and autoscaling. | ✅ Active |

---

## 🛠️ Technology Stack

| Component | Software | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **OS** | [Talos Linux](https://www.talos.dev/) | `v1.9.1` | The foundation. Secure, minimal K8s OS. |
| **Kernel** | Linux | `6.x` | Optimized for container workloads. |
| **Container Runtime** | Containerd | `Latest` | Industry standard runtime. |
| **CNI** | Flannel | `Latest` | Simple, robust overlay networking. |
| **Load Balancer** | MetalLB | `v0.15.3` | Bare-metal LoadBalancer implementation. |
| **Ingress** | Traefik | `v3.x` | Edge router & service proxy. |
| **Storage** | Longhorn | `Latest` | Cloud-native distributed block storage. |
| **Cert-Manager** | Cert-Manager | `v1.16.x` | X.509 certificate management. |

---

## 📂 Project Structure & Guides

Start your journey here steps 1 through 6:

| # | Directory | Module Description |
| :--- | :--- | :--- |
| **01** | **[01-talos-bootstrap/](./01-talos-bootstrap/)** | **Bootstrap:** OS Install, Network Config, & Etcd Cluster Init. |
| **02** | **[02-metallb/](./02-metallb/)** | **Networking:** MetalLB setup for Service IP pools. |
| **03** | **[03-metrics-server/](./03-metrics-server/)** | **Monitoring:** Enable `kubectl top` and HPA. |
| **04** | **[04-traefik-ingress/](./04-traefik-ingress/)** | **Ingress:** Traefik Controller & Magic DNS. |
| **05** | **[05-cert-manager/](./05-cert-manager/)** | **Security:** HTTPS & Self-Signed Certificates. |

| **06** | **[06-storage-longhorn/](./06-storage-longhorn/)** | **Storage:** Persistent Volumes & Longhorn UI. |
| **07** | **[07-dashboard-headlamp/](./07-dashboard-headlamp/)** | **Dashboard:** Headlamp UI & Admin Access. |
| **08** | **[08-gateway-envoy/](./08-gateway-envoy/)** | **Gateway API:** Modern Envoy Gateway implementation. |

---

## 🔧 High Availability
| Doc | Description |
| :--- | :--- |
| **[HA-VERIFICATION.md](./HA-VERIFICATION.md)** | Guide for verifying cluster health during node failures. |

---

## 🚀 Access & Usage

### 🔑 Cluster Access
```bash
# Point kubectl to the local config
export KUBECONFIG=$(pwd)/kubeconfig

# Check Nodes
kubectl get nodes -o wide
```

### 🖥️ Dashboards & endpoints
| Service | URL | Protocol |
| :--- | :--- | :--- |
| **Whoami App** | `http://whoami.172.16.16.101.sslip.io` | HTTP |
| **Whoami (Secure)**| `https://whoami.172.16.16.101.sslip.io` | HTTPS 🔒 |
| **Longhorn UI** | `http://longhorn.172.16.16.101.sslip.io` | HTTP |
| **Headlamp Dashboard** | `https://headlamp.172.16.16.101.sslip.io` | HTTPS 🔒 |

---

## 🗺️ High-Level Architecture

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#e3f2fd', 'primaryTextColor': '#0d47a1', 'primaryBorderColor': '#1976d2', 'lineColor': '#424242', 'secondaryColor': '#fff3e0', 'tertiaryColor': '#f3e5f5'}}}%%

graph TB
    %% ═══════════════════════════════════════════════════════════════════════
    %% EXTERNAL LAYER
    %% ═══════════════════════════════════════════════════════════════════════
    user(("🌍 Internet<br/>Users & Clients"))

    subgraph VIP_LAYER ["🔴 Virtual IP Layer"]
        vip["<b>VIP: 172.16.16.100</b><br/>Floats to Active Leader"]
    end

    %% ═══════════════════════════════════════════════════════════════════════
    %% CONTROL PLANE
    %% ═══════════════════════════════════════════════════════════════════════
    subgraph CLUSTER ["🦅 Talos Kubernetes Cluster (v1.35 on Talos v1.9)"]
        direction TB

        subgraph CP ["🧠 Control Plane (Stacked Etcd)"]
            direction LR
            cp1["<b>cp01</b><br/>172.16.16.147<br/>🟢 Leader"]
            cp2["<b>cp02</b><br/>172.16.16.148<br/>⚪ Follower"]
            cp3["<b>cp03</b><br/>172.16.16.149<br/>⚪ Follower"]
        end

        %% ═══════════════════════════════════════════════════════════════════
        %% SYSTEM COMPONENTS
        %% ═══════════════════════════════════════════════════════════════════
        subgraph SYSTEM ["⚙️ Core System Components"]
            direction LR
            flannel["🔗 Flannel CNI<br/>(Pod Network: 10.244.0.0/16)"]
            metallb["⚖️ MetalLB<br/>(IPs: .101-.120)"]
            certmgr["🔐 Cert-Manager<br/>(Self-Signed TLS)"]
            metrics["📊 Metrics Server<br/>(kubectl top)"]
        end

        %% ═══════════════════════════════════════════════════════════════════
        %% STORAGE
        %% ═══════════════════════════════════════════════════════════════════
        subgraph STORAGE ["💾 Distributed Storage"]
            longhorn["📦 Longhorn<br/>(Replicated Block Storage)<br/>UI: longhorn.101.sslip.io"]
        end

        %% ═══════════════════════════════════════════════════════════════════
        %% TRAFFIC CONTROLLERS
        %% ═══════════════════════════════════════════════════════════════════
        subgraph INGRESS ["🚦 Traffic Controllers"]
            direction TB

            subgraph INGRESS_API ["📉 Ingress API (Legacy)"]
                traefik["🏁 <b>Traefik v3</b><br/>IP: 172.16.16.101<br/>*.101.sslip.io"]
            end

            subgraph GATEWAY_API ["🚀 Gateway API (Modern)"]
                envoy["🛡️ <b>Envoy Gateway v1.6</b><br/>IP: 172.16.16.102<br/>*.102.sslip.io"]
            end
        end

        %% ═══════════════════════════════════════════════════════════════════
        %% DASHBOARDS
        %% ═══════════════════════════════════════════════════════════════════
        subgraph DASHBOARDS ["🖥️ Management Dashboards"]
            headlamp["💡 Headlamp<br/>headlamp.101.sslip.io"]
        end

        %% ═══════════════════════════════════════════════════════════════════
        %% WORKER NODES
        %% ═══════════════════════════════════════════════════════════════════
        subgraph WORKERS ["💪 Worker Nodes (Data Plane)"]
            direction LR
            wk1["<b>wk01</b><br/>172.16.16.150<br/>📦 Pods"]
            wk2["<b>wk02</b><br/>172.16.16.151<br/>📦 Pods"]
            wk3["<b>wk03</b><br/>172.16.16.152<br/>📦 Pods"]
        end
    end

    %% ═══════════════════════════════════════════════════════════════════════
    %% CONNECTIONS
    %% ═══════════════════════════════════════════════════════════════════════
    user --> VIP_LAYER
    VIP_LAYER --> CP

    CP --> SYSTEM
    SYSTEM --> STORAGE
    SYSTEM --> INGRESS

    traefik --> WORKERS
    envoy --> WORKERS

    longhorn -.-> wk1
    longhorn -.-> wk2
    longhorn -.-> wk3

    %% ═══════════════════════════════════════════════════════════════════════
    %% STYLING
    %% ═══════════════════════════════════════════════════════════════════════
    style CLUSTER fill:#fafafa,stroke:#333,stroke-width:3px
    style CP fill:#e0f7fa,stroke:#006064,stroke-width:2px
    style WORKERS fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style SYSTEM fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style STORAGE fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style INGRESS fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style INGRESS_API fill:#f5f5f5,stroke:#9e9e9e,stroke-dasharray: 5 5
    style GATEWAY_API fill:#bbdefb,stroke:#1976d2,stroke-width:2px
    style DASHBOARDS fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    style VIP_LAYER fill:#ffcdd2,stroke:#c62828,stroke-width:2px

    style cp1 fill:#c8e6c9,stroke:#2e7d32
    style cp2 fill:#fff,stroke:#9e9e9e
    style cp3 fill:#fff,stroke:#9e9e9e
    style traefik fill:#eee,stroke:#424242
    style envoy fill:#2979ff,stroke:#0d47a1,color:#fff
```


## 🌐 Network & IP Plan

| IP Address | Hostname | Role |
| :--- | :--- | :--- |
| `172.16.16.147` | `cp01` | Control Plane 01 |
| `172.16.16.148` | `cp02` | Control Plane 02 |
| `172.16.16.149` | `cp03` | Control Plane 03 |
| `172.16.16.150` | `wk01` | Worker Node 01 |
| `172.16.16.151` | `wk02` | Worker Node 02 |
| `172.16.16.152` | `wk03` | Worker Node 03 |
| **`172.16.16.100`** | **VIP** | **Control Plane VIP** |
| **`172.16.16.101`** | **Traefik** | **Standard Ingress** |
| **`172.16.16.102`** | **Envoy** | **Gateway API** |
| `172.16.16.101-120` | MetalLB | Service IP Pool |