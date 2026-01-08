# ☸️ Kubernetes HA on Talos Linux

Welcome to the **Ultimate Kubernetes High Availability Cluster** lab!
This project demonstrates a production-grade, fully automated Kubernetes cluster built on **Talos Linux**, designed for resilience, security, and modern GitOps practices.

---

## 🗺️ High-Level Architecture (Master View)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'primaryTextColor': '#212121', 'lineColor': '#424242', 'fontFamily': 'arial'}}}%%

graph LR
    %% ==========================================
    %% 1. EXTERNAL WORLD
    %% ==========================================
    subgraph S1 ["🌍 Sources"]
        direction TB
        admin(("👨‍💻 <b>Admin</b><br/>(DevOps)"))
        user(("👥 <b>User</b><br/>(HTTPS)"))
    end

    %% ==========================================
    %% 2. NETWORK GATEWAY (MetalLB)
    %% ==========================================
    subgraph S2 ["🔌 Network Entry (MetalLB L2)"]
        direction TB
        note_arp["<i>📢 Announces IPs via ARP</i>"]

        vip["🔴 <b>VIP: .100</b><br/>(API Gateway)"]
        legacy_ip["🏁 <b>IP: .101</b><br/>(Traefik Pool)"]
        modern_ip["🛡️ <b>IP: .102</b><br/>(Envoy Pool)"]
    end

    %% ==========================================
    %% 3. TALOS CLUSTER (6 NODES)
    %% ==========================================
    subgraph S3 ["🛡️ Talos HA Cluster (Immutable OS)"]
        direction LR

        %% 🧠 CONTROL PLANE
        subgraph CP ["🧠 Control Plane (Masters)"]
            direction TB
            api["☸️ <b>K8s API</b>"]

            subgraph CP_NODES ["Hardware"]
                cp1["<b>cp01</b><br/>.147"]
                cp2["<b>cp02</b><br/>.148"]
                cp3["<b>cp03</b><br/>.149"]
            end
        end

        %% 💪 DATA PLANE
        subgraph WORKERS ["💪 Data Plane (Workers)"]
            direction TB

            subgraph WK_NODES ["Hardware"]
                wk1["<b>wk01</b><br/>.150"]
                wk2["<b>wk02</b><br/>.151"]
                wk3["<b>wk03</b><br/>.152"]
            end

            %% WORKLOADS RUNNING ON WORKERS
            subgraph ROUTING ["🚦 Routing Layer"]
                cert("🔐 Cert-Mgr")
                traefik("🏁 Traefik v3")
                envoy("🛡️ Envoy v1.6")
            end

            subgraph APPS ["📦 Workloads"]
                app("📱 User Apps")
            end
        end
    end

    %% ==========================================
    %% 4. STORAGE
    %% ==========================================
    subgraph S4 ["💾 Persistence"]
        longhorn[("📦 <b>Longhorn</b><br/>(Distributed Block)")]
    end

    %% ==========================================
    %% TRAFFIC FLOWS
    %% ==========================================

    %% Admin Path
    admin == "Manage" ==> vip
    vip ==> api
    api -.-> CP_NODES

    %% User Path (Legacy)
    user -- "Legacy" --> legacy_ip
    legacy_ip == "Routes to" ==> traefik
    traefik --> app

    %% User Path (Modern)
    user -- "Modern" --> modern_ip
    modern_ip == "Routes to" ==> envoy
    envoy --> app

    %% Internal Wiring
    cert -. "Injects" .- traefik
    cert -. "Injects" .- envoy

    app == "PVC" ==> longhorn

    %% Physical Hosting (Conceptual)
    WK_NODES -.- ROUTING
    WK_NODES -.- APPS

    %% ==========================================
    %% STYLING
    %% ==========================================
    style S1 fill:none,stroke:none
    style S2 fill:#fafafa,stroke:#616161,stroke-dasharray: 5 5
    style S3 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style S4 fill:#fff3e0,stroke:#e65100

    style CP fill:#e1f5fe,stroke:#0277bd
    style WORKERS fill:#f3e5f5,stroke:#7b1fa2

    style vip fill:#ffcdd2,stroke:#c62828
    style legacy_ip fill:#fff9c4,stroke:#fbc02d
    style modern_ip fill:#bbdefb,stroke:#1976d2

    style cp1 fill:#fff,stroke:#0277bd
    style cp2 fill:#fff,stroke:#0277bd
    style cp3 fill:#fff,stroke:#0277bd

    style wk1 fill:#fff,stroke:#7b1fa2
    style wk2 fill:#fff,stroke:#7b1fa2
    style wk3 fill:#fff,stroke:#7b1fa2

    style traefik fill:#fff9c4,stroke:#fbc02d
    style envoy fill:#bbdefb,stroke:#1976d2
    style cert fill:#263238,stroke:#000,color:#fff
```

---

### 🚦 Detailed Traffic Paths

#### 1. Legacy Ingress Flow (Traefik)
*Standard Kubernetes Ingress for existing workloads.*

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#fff9c4', 'lineColor': '#fbc02d', 'fontFamily': 'arial'}}}%%
graph LR
    user(("👤 <b>User</b>"))

    subgraph L2 ["🔌 Layer 2"]
        lb["🏁 <b>MetalLB IP</b><br/>172.16.16.101"]
    end

    subgraph K8S ["☸️ Kubernetes"]
        ing_con["🏁 <b>Traefik Controller</b><br/>(Listener)"]
        ing_res["📄 <b>Ingress</b><br/>(Rules)"]
        svc["🧩 <b>Service</b>"]
        pod["📦 <b>Pod</b>"]
    end

    user -- "HTTPS" --> lb
    lb -- "ARP -> Pod IP" --> ing_con
    ing_con -- "Match Host" --> ing_res
    ing_res -- "Route" --> svc
    svc --> pod

    style L2 fill:#fffde7,stroke:#fbc02d
    style K8S fill:#fafafa,stroke:#ccc
```

#### 2. Modern Gateway Flow (Envoy)
*Next-Gen Gateway API for advanced routing.*

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#bbdefb', 'lineColor': '#1976d2', 'fontFamily': 'arial'}}}%%
graph LR
    user(("👤 <b>User</b>"))

    subgraph L2 ["🔌 Layer 2"]
        lb["🛡️ <b>MetalLB IP</b><br/>172.16.16.102"]
    end

    subgraph K8S ["☸️ Kubernetes"]
        gw_con["🛡️ <b>Envoy Gateway</b><br/>(Listener)"]
        route["⚡ <b>HTTPRoute</b><br/>(Advanced Rules)"]
        svc["🧩 <b>Service</b>"]
        pod["📦 <b>Pod</b>"]
    end

    user -- "HTTPS" --> lb
    lb -- "ARP -> Pod IP" --> gw_con
    gw_con -- "Match Header/Path" --> route
    route -- "Split/Filter" --> svc
    svc --> pod

    style L2 fill:#e3f2fd,stroke:#1976d2
    style K8S fill:#fafafa,stroke:#ccc
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
| **100** | [100-workloads/](./100-workloads/) | Example Workloads |

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
| **👾 KubeInvaders** | `http://kubeinvaders.172.16.16.102.sslip.io` | **Modern Path (.102)** |
| **🚦 Whoami App** | `https://whoami.172.16.16.101.sslip.io` | **Legacy Path (.101)** |
| **🖥️ Headlamp Dashboard**| `https://headlamp.172.16.16.101.sslip.io` | Web UI |
| **💿 Longhorn UI** | `http://longhorn.172.16.16.101.sslip.io` | Web UI |
| **🔧 Metrics Server** | `kubectl top nodes` | CLI Only |

---

## 🔧 HA Verification

| Doc | Description |
| :--- | :--- |
| [HA-VERIFICATION.md](./HA-VERIFICATION.md) | Guide for verifying cluster health during node failures. |