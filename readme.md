# 🦅 Kubernetes HA on Talos Linux

Welcome to the **Ultimate Kubernetes High Availability Cluster** lab!
This project demonstrates a production-grade, fully automated Kubernetes cluster built on **Talos Linux**, designed for resilience, security, and modern GitOps practices.

---

## 🗺️ High-Level Architecture (Logical Traffic Flow)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#212121', 'lineColor': '#424242', 'fontFamily': 'arial'}}}%%

graph LR
    %% ==========================================
    %% 1. EXTERNAL
    %% ==========================================
    subgraph S1 ["🌍 External Source"]
        direction TB
        admin(("👨‍💻 <b>Admin</b><br/>(kubectl)"))
        user(("👤 <b>User</b><br/>(HTTPS)"))
    end

    %% ==========================================
    %% 2. NETWORK ENTRANCE (METALLB)
    %% ==========================================
    subgraph S2 ["🔌 Network Entry (MetalLB L2)"]
        direction TB
        note_lb["<i>Announces IPs via ARP</i>"]
        vip["🔴 <b>VIP .100</b><br/>(Cluster API)"]
        lb_legacy["🏁 <b>IP .101</b><br/>(Legacy Pool)"]
        lb_modern["🛡️ <b>IP .102</b><br/>(Gateway Pool)"]
    end

    %% ==========================================
    %% 3. CLUSTER & ROUTING
    %% ==========================================
    subgraph S3 ["🦅 Talos Cluster"]
        direction TB

        subgraph CP ["🧠 Control Plane"]
            api["☸️ API Server"]
        end

        subgraph ROUTING ["🚦 Ingress & Gateway Layer"]
            direction TB
            certmgr("🔐 <b>Cert-Manager</b><br/>(Auto TLS Issuance)")

            subgraph R_LEGACY ["Standard Ingress"]
                traefik("🏁 <b>Traefik v3</b><br/>(Controller)")
            end

            subgraph R_MODERN ["Gateway API"]
                envoy("🛡️ <b>Envoy v1.6</b><br/>(Gateway)")
            end
        end

        subgraph APPS ["📦 Application Layer"]
            my_app("📱 User Applications<br/>(Podinfo / Websites)")
        end
    end

    %% ==========================================
    %% 4. STORAGE LAYER
    %% ==========================================
    subgraph S4 ["💾 Persistence"]
        longhorn[("📦 <b>Longhorn</b><br/>(Distributed Block Storage)")]
    end

    %% ==========================================
    %% TRAFFIC FLOWS
    %% ==========================================

    %% Admin Path
    admin == "Manage" ==> vip
    vip ==> api

    %% User Path (Legacy)
    user -- "https://*.101.sslip.io" --> lb_legacy
    lb_legacy == "Routes to" ==> traefik
    traefik --> my_app

    %% User Path (Modern)
    user -- "https://*.102.sslip.io" --> lb_modern
    lb_modern == "Routes to" ==> envoy
    envoy --> my_app

    %% Internal Wiring
    certmgr -. "Injects Secrets" .- traefik
    certmgr -. "Injects Secrets" .- envoy

    my_app == "PVC Mount" ==> longhorn

    %% ==========================================
    %% STYLING
    %% ==========================================
    style S1 fill:none,stroke:none
    style S2 fill:#fafafa,stroke:#616161,stroke-dasharray: 5 5
    style S3 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style S4 fill:#fff3e0,stroke:#e65100

    style CP fill:#e1f5fe,stroke:#0277bd
    style ROUTING fill:#f3e5f5,stroke:#7b1fa2
    style APPS fill:#fff,stroke:#333

    style vip fill:#ffcdd2,stroke:#c62828
    style lb_legacy fill:#fff9c4,stroke:#fbc02d
    style lb_modern fill:#bbdefb,stroke:#1976d2

    style certmgr fill:#263238,stroke:#000,color:#fff
    style traefik fill:#fff9c4,stroke:#fbc02d
    style envoy fill:#bbdefb,stroke:#1976d2
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