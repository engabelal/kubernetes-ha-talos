# 🐧 Talos Linux Bootstrap

**Control Plane:**
```bash
talosctl apply-config --insecure --nodes 172.16.16.147 --file cp01.yaml
talosctl apply-config --insecure --nodes 172.16.16.148 --file cp02.yaml
talosctl apply-config --insecure --nodes 172.16.16.149 --file cp03.yaml
```

**Workers:**
```bash
talosctl apply-config --insecure --nodes 172.16.16.150 --file wk01.yaml
talosctl apply-config --insecure --nodes 172.16.16.151 --file wk02.yaml
talosctl apply-config --insecure --nodes 172.16.16.152 --file wk03.yaml
```

### 2. Bootstrap Etcd
Run this **ONCE** on the first CP node (`147`).
```bash
talosctl config endpoint 172.16.16.147
talosctl config node 172.16.16.147
talosctl bootstrap
```
*(Wait key VIP `172.16.16.100` to become active)*

```bash
talosctl kubeconfig . --force
```
