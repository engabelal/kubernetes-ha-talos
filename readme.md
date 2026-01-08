# 🦅 Kubernetes HA on Talos Linux

Welcome to the **Ultimate Kubernetes High Availability Cluster** lab!
This project demonstrates a production-grade, fully automated Kubernetes cluster built on **Talos Linux**, designed for resilience, security, and modern GitOps practices.

---

## 🗺️ High-Level Architecture

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#212121', 'lineColor': '#424242', 'fontFamily': 'arial'}}}%%

graph LR
    %% ==========================================
    %% 1. EXTERNAL ACTORS
    %% ==========================================
    subgraph S1 ["🌍  External Access"]
        direction TB
        admin(("👨‍💻 Admin<br/>(DevOps)"))
        user(("🌐 User<br/>(Internet)"))
    end

    %% ==========================================
    %% 2. NETWORK ENTRANCE (LAYER 2)
    %% ==========================================
    subgraph S2 ["🔌 Network Entry (MetalLB & VIP)"]
        direction TB
        vip_ep["🔴 <b>Control Plane VIP</b><br/>172.16.16.100"]
        lb_traefik["🏁 <b>Traefik IP</b><br/>172.16.16.101"]
        lb_envoy["🛡️ <b>Envoy IP</b><br/>172.16.16.102"]
    end

    %% ==========================================
    %% 3. INFRASTRUCTURE (THE CLUSTER)
    %% ==========================================
    subgraph S3 ["🦅 Talos Kubernetes Cluster"]
        direction LR

        %% CONTROL PLANE
        subgraph CP ["🧠 Control Plane (Masters)"]
            direction TB
            cp01["<b>cp01</b> .147"]
            cp02["<b>cp02</b> .148"]
            cp03["<b>cp03</b> .149"]
        end

        %% DATA PLANE
        subgraph WORKERS ["💪 Data Plane (Workers)"]
            direction TB
            wk01["<b>wk01</b> .150"]
            wk02["<b>wk02</b> .151"]
            wk03["<b>wk03</b> .152"]

            %% RUNNING COMPONENTS
            traefik_pod("🏁 Traefik Controller")
            envoy_pod("🛡️ Envoy Gateway")
            apps("📦 User Apps")
        end
    end

    %% ==========================================
    %% 4. STORAGE
    %% ==========================================
    subgraph S4 ["💾 Persistence Layer"]
        longhorn[("📦 Longhorn Storage<br/>(Distributed Block)")]
    end

    %% ==========================================
    %% CONNECTIONS (WHO TALKS TO WHOM)
    %% ==========================================

    %% Admin Flow (Management)
    admin == "kubectl / API" ==> vip_ep
    vip_ep -- "Load Balances" --> cp01
    vip_ep -- "Load Balances" --> cp02
    vip_ep -- "Load Balances" --> cp03

    %% User Flow (Traffic)
    user -- "Legacy Ingress" --> lb_traefik
    user -- "Gateway API" --> lb_envoy

    lb_traefik == "Routes to" ==> traefik_pod
    lb_envoy == "Routes to" ==> envoy_pod

    %% Ingress to Apps
    traefik_pod -.-> apps
    envoy_pod -.-> apps

    %% Nodes hosting Pods (Implicit conceptual link)
    wk01 --- traefik_pod
    wk02 --- envoy_pod
    wk03 --- apps

    %% Storage Attachment
    apps == "Mounts PVC" ==> longhorn
    wk01 --- longhorn
    wk02 --- longhorn
    wk03 --- longhorn

    %% ==========================================
    %% STYLING
    %% ==========================================
    style S1 fill:none,stroke:none
    style S2 fill:#fcfcfc,stroke:#9e9e9e,stroke-dasharray: 5 5
    style S3 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style CP fill:#e1f5fe,stroke:#0277bd
    style WORKERS fill:#f3e5f5,stroke:#7b1fa2
    style S4 fill:#fff3e0,stroke:#e65100

    style vip_ep fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    style lb_traefik fill:#fff9c4,stroke:#fbc02d
    style lb_envoy fill:#bbdefb,stroke:#1976d2

    style cp01 fill:#fff,stroke:#0277bd
    style cp02 fill:#fff,stroke:#0277bd
    style cp03 fill:#fff,stroke:#0277bd

    style wk01 fill:#fff,stroke:#7b1fa2
    style wk02 fill:#fff,stroke:#7b1fa2
    style wk03 fill:#fff,stroke:#7b1fa2

    style traefik_pod fill:#fff9c4,stroke:#fbc02d
    style envoy_pod fill:#bbdefb,stroke:#1976d2
```

---

## 🌐 Network & IP Plan

| IP Address | Hostname | Role |
| :--- | :--- | :--- |
| `172.16.16.147` | `cp01` | Control Plane 01 (Leader) |
| `172.16.16.148` | `cp02` | Control Plane 02 |
| `172.16.16.149` | `cp03` | Control Plane 03 |
| `172.16.16.150` | `wk01` | Worker Node 01 |
| `172.16.16.151` | `wk02` | Worker Node 02 |
| `172.16.16.152` | `wk03` | Worker Node 03 |
| **`172.16.16.100`** | **VIP** | **Control Plane VIP** |
| **`172.16.16.101`** | **Traefik** | **Ingress (Legacy)** |
| **`172.16.16.102`** | **Envoy** | **Gateway API (Modern)** |
| `172.16.16.101-120` | MetalLB | Service IP Pool |

---

## 🌟 Features & Capabilities

| Feature | Description | Status |
| :--- | :--- | :--- |
| **👑 HA Control Plane** | 3-node stacked etcd with floating VIP (`.100`) | 🟢 **Ready** |
| **🔒 Immutable OS** | Talos Linux: API-Only, No SSH, Read-Only FS | 🛡️ **Hardened** |
| **⚖️ L2 Load Balancer** | MetalLB providing physical IP assignment to LB types | ⚡ **Active** |
| **🚦 Traffic Switching** | Traefik (Legacy) & Envoy (Modern) co-existence | 🛤️ **Configured** |
| **🪄 Magic DNS** | Full `sslip.io` integration for automated subdomains | 🌐 **Enabled** |
| **🔐 SSL/TLS Automation**| Cert-Manager issuing per-service certificates | 🛡️ **Verified** |
| **📦 Distributed Storage**| Longhorn replicated PVs across all worker nodes | 💿 **Storage OK** |
| **📊 Dashboarding** | Headlamp & Longhorn UI for management | 🖥️ **Live** |

---

## 🛠️ Technology Stack

| Component | Software | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **OS** | [Talos Linux](https://www.talos.dev/) | `v1.9.1` | Security-first, API-managed OS |
| **Orchestrator** | Kubernetes | `v1.35.0` | Container orchestration engine |
| **CNI** | Flannel | `v0.26.x` | Pod networking & VXLAN overlay |
| **Load Balancer** | MetalLB | `v0.15.3` | Layer 2 bare-metal LoadBalancer |
| **Ingress** | Traefik | `v3.3.x` | Standard Ingress routing (`.101`) |
| **Gateway API** | Envoy Gateway | `v1.6.1` | Modern Gateway API routing (`.102`) |
| **Storage** | Longhorn | `v1.7.x` | Distributed block storage for PVs |
| **Cert-Manager** | Cert-Manager | `v1.16.x` | Certificate lifecycle management |
| **Metrics** | Metrics Server | `v0.7.x` | Resource tracking (CPU/RAM) |

---

## 📂 Project Structure

| # | Directory | Description |
| :--- | :--- | :--- |
| **01** | [01-talos-bootstrap/](./01-talos-bootstrap/) | OS Install & Etcd Init |
| **02** | [02-metallb/](./02-metallb/) | MetalLB IP Pool |
| **03** | [03-metrics-server/](./03-metrics-server/) | Metrics Server |
| **04** | [04-traefik-ingress/](./04-traefik-ingress/) | Traefik Ingress |
| **05** | [05-cert-manager/](./05-cert-manager/) | TLS Certificates |
| **06** | [06-storage-longhorn/](./06-storage-longhorn/) | Longhorn Storage |
| **07** | [07-dashboard-headlamp/](./07-dashboard-headlamp/) | Headlamp UI |
| **08** | [08-gateway-envoy/](./08-gateway-envoy/) | Envoy Gateway API |

---

## 🚀 Quick Access

### 🔑 Cluster Access
```bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes -o wide
```

### 🖥️ Dashboards & Endpoints

| Service | URL | Access Protocol |
| :--- | :--- | :--- |
| **🚀 Envoy Demo** | `http://demo.172.16.16.102.sslip.io` | **Modern Path (.102)** |
| **🚦 Whoami App** | `https://whoami.172.16.16.101.sslip.io` | **Legacy Path (.101)** |
| **🖥️ Headlamp Dashboard**| `https://headlamp.172.16.16.101.sslip.io` | Web UI |
| **💿 Longhorn UI** | `http://longhorn.172.16.16.101.sslip.io` | Web UI |
| **🔧 Metrics Server** | `kubectl top nodes` | CLI Only |

---

## 🔧 HA Verification

| Doc | Description |
| :--- | :--- |
| [HA-VERIFICATION.md](./HA-VERIFICATION.md) | Guide for verifying cluster health during node failures. |