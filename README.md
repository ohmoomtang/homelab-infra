# homelab-infra

Infrastructure-as-Code for a self-hosted homelab running on Proxmox VE, provisioned and managed with Terraform and Ansible.

## Architecture

```
Internet
    │
TP-Link Router (DHCP → AdGuard DNS)
    │
Proxmox VE (Dell OptiPlex Micro, i5-8500T, 32GB RAM)
    │
    ├── LXC Containers (unprivileged, ZFS-backed)
    │   ├── AdGuard Primary      192.168.0.84  (DNS, Ad-blocking)
    │   ├── AdGuard Secondary    192.168.0.85  (DNS, Ad-blocking)
    │   ├── AdGuard Sync         192.168.0.83  (Config Sync)
    │   ├── Monitoring           192.168.0.81  (Grafana + Loki + Prometheus)
    │   ├── Uptime Kuma          192.168.0.82  (Uptime Monitoring)
    │   ├── Supabase             192.168.0.22  (Backend Platform)
    │   ├── Jellyfin             192.168.0.41  (Media Server)
    │   └── Vert                 192.168.0.52  (File Converter)
    │
    └── K3s VMs (cloned from Ubuntu template)
        ├── k3s-control-plane    192.168.0.71  (K3s server)
        ├── k3s-worker-01        192.168.0.72  (K3s agent)
        └── k3s-worker-02        192.168.0.73  (K3s agent)
```

LXC containers run unprivileged on a ZFS storage backend (`local-zfs`), bridged on `vmbr0`. K3s VMs are cloned from an Ubuntu VM template (VMID 9000) with static IPs in the `192.168.0.0/24` subnet.

## Stack

| Category                 | Tools                            |
| ------------------------ | -------------------------------- |
| Hypervisor               | Proxmox VE                       |
| IaC                      | Terraform (bpg/proxmox ~> 0.76)  |
| Configuration Management | Ansible                          |
| Container Orchestration  | K3s (Kubernetes)                 |
| DNS & Ad-blocking        | AdGuard Home                     |
| Monitoring               | Grafana, Prometheus, Loki        |
| Log/Metrics Collection   | Grafana Alloy                    |
| Uptime Monitoring        | Uptime Kuma                      |
| Media                    | Jellyfin                         |
| Backend Platform         | Supabase (self-hosted via CLI)   |
| File Converter           | Vert                             |

## Prerequisites

- Proxmox VE installed and accessible via API
- Terraform >= 1.2
- Ansible >= 2.13
- Python 3.x
- `community.docker`, `grafana.grafana`, and `community.general` Ansible collections
  - All three are bundled with `pip install ansible` (no extra step needed)
  - If using `ansible-core`, install them manually:

```bash
ansible-galaxy collection install community.docker grafana.grafana community.general
```

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/ohmoomtang/homelab-infra.git
cd homelab-infra
```

### 2. Configure Terraform variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform.tfvars` with your Proxmox credentials:

```hcl
proxmox_pve_endpoint      = "https://192.168.0.x:8006"
proxmox_pve_api_token     = "root@pam!terraform=xxxx"
proxmox_node              = "pve1"
ssh_public_key            = "ssh-ed25519 AAAA..."
default_lxc_root_password = "your-password"
```

### 3. Provision LXC Containers

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Configure Ansible Vault

Sensitive credentials are stored in per-role vault files (already encrypted). Edit each one to fill in your own credentials:

```bash
ansible-vault edit ansible/roles/monitoring/vault.yml
ansible-vault edit ansible/roles/adguard-sync/vault.yml
ansible-vault edit ansible/inventories/k3s/vault.yml
```

### 5. Run Ansible Playbooks

Specify the inventory with `-i` since this repo uses multiple inventory directories.

```bash
cd ansible

# Harden and configure all LXC hosts
ansible-playbook -i inventories/homelab playbooks/base.yml

# Deploy services
ansible-playbook -i inventories/homelab playbooks/adguard.yml
ansible-playbook -i inventories/homelab playbooks/adguardsync.yml
ansible-playbook -i inventories/homelab playbooks/monitoring.yml
ansible-playbook -i inventories/homelab playbooks/uptimekuma.yml
ansible-playbook -i inventories/homelab playbooks/jellyfin.yml
ansible-playbook -i inventories/homelab playbooks/supabase.yml
ansible-playbook -i inventories/homelab playbooks/vert.yml

# Deploy Alloy metrics/log agent on all Debian hosts
ansible-playbook -i inventories/homelab playbooks/alloy.yml

# Apply rolling APT/APK updates across all LXC containers
ansible-playbook -i inventories/homelab playbooks/update_lxc.yml
```

> **Note:** Vault-encrypted files require `--ask-vault-pass` or a vault password file.

### 6. Deploy K3s Cluster

Run K3s-specific playbooks using the `k3s` inventory. Vault credentials are stored in `inventories/k3s/vault.yml`.

```bash
cd ansible

# Run a playbook against the K3s cluster
ansible-playbook -i inventories/k3s playbooks/<name>.yml --ask-vault-pass

# Target a single node
ansible-playbook -i inventories/k3s playbooks/<name>.yml --limit k3s-control-plane --ask-vault-pass
```

## Repository Structure

```
homelab-infra/
├── terraform/
│   ├── main.tf                      # Provider + backend config
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vm_k3s.tf                    # K3s VM cluster (1 server + 2 agents)
│   ├── lxc_adguard.tf               # AdGuard primary + secondary
│   ├── lxc_adguard_sync.tf
│   ├── lxc_monitoring.tf
│   ├── lxc_uptime_kuma.tf
│   ├── lxc_jellyfin.tf
│   ├── lxc_supabase.tf
│   ├── lxc_vert.tf
│   └── terraform.tfvars.example
└── ansible/
    ├── ansible.cfg
    ├── inventories/
    │   ├── homelab/                  # LXC containers inventory
    │   │   ├── hosts.yml
    │   │   └── group_vars/
    │   │       └── all.yml
    │   └── k3s/                      # K3s cluster inventory
    │       ├── hosts.yml
    │       ├── group_vars/
    │       │   └── all.yml           # k3s_channel, k3s_version, api_endpoint
    │       └── vault.yml             # Encrypted K3s credentials
    ├── playbooks/
    │   ├── base.yml
    │   ├── adguard.yml
    │   ├── adguardsync.yml
    │   ├── monitoring.yml
    │   ├── uptimekuma.yml
    │   ├── jellyfin.yml
    │   ├── supabase.yml
    │   ├── vert.yml
    │   ├── alloy.yml
    │   └── update_lxc.yml            # Rolling APT/APK updates
    └── roles/
        ├── base/                     # Ubuntu/Debian hardening + admin user
        ├── base-alpine/              # Alpine hardening + admin user
        ├── docker/                   # Docker CE on Ubuntu
        ├── docker-alpine/            # Docker on Alpine
        ├── adguard/                  # AdGuard Home container
        ├── adguard-sync/             # AdGuard config sync (cron every 10m)
        ├── monitoring/               # Grafana + Prometheus + Loki via Compose
        ├── uptimekuma/               # Uptime Kuma via Compose
        ├── jellyfin/                 # Jellyfin with GPU passthrough
        ├── supabase/                 # Supabase via CLI + systemd
        ├── vert/                     # Vert file converter via Compose
        └── alloy/                    # Grafana Alloy agent (Debian hosts only)
├── helm/
│   ├── loki/
│   │   └── values.yaml               # Loki log aggregation
│   ├── promtail/
│   │   └── values.yaml               # Promtail log shipper
│   └── tempo/
│       └── values.yaml               # Tempo distributed tracing
└── k8s/
    └── manifests/                    # future K3s workload manifests
```

## IP Addressing Scheme

| Range        | Category             |
| ------------ | -------------------- |
| 192.168.0.2x | Middleware / Backend |
| 192.168.0.4x | Media                |
| 192.168.0.5x | General apps         |
| 192.168.0.7x | K3s cluster          |
| 192.168.0.8x | Utility / Network    |

## Inventory

### LXC Containers

| VM ID | Hostname          | IP            | CPU | RAM    | OS     |
| ----- | ----------------- | ------------- | --- | ------ | ------ |
| 100   | adguard-primary   | 192.168.0.84  | 1   | 1 GB   | Alpine |
| 101   | adguard-secondary | 192.168.0.85  | 1   | 1 GB   | Alpine |
| 102   | adguard-sync      | 192.168.0.83  | 1   | 256 MB | Ubuntu |
| 103   | monitoring        | 192.168.0.81  | 2   | 2 GB   | Ubuntu |
| 104   | uptime-kuma       | 192.168.0.82  | 1   | 512 MB | Ubuntu |
| 105   | jellyfin          | 192.168.0.41  | 4   | 2 GB   | Ubuntu |
| 108   | vert              | 192.168.0.52  | 1   | 512 MB | Ubuntu |
| 109   | supabase          | 192.168.0.22  | 4   | 8 GB   | Ubuntu |

### K3s VMs

| VM ID | Hostname          | IP            | CPU | RAM  | Role          |
| ----- | ----------------- | ------------- | --- | ---- | ------------- |
| 171   | k3s-control-plane | 192.168.0.71  | 2   | 4 GB | K3s server    |
| 172   | k3s-worker-01     | 192.168.0.72  | 2   | 4 GB | K3s agent     |
| 173   | k3s-worker-02     | 192.168.0.73  | 2   | 4 GB | K3s agent     |

## Manual Post-Provisioning Steps

Some features require manual configuration due to Proxmox API limitations:

```bash
# Enable keyctl for monitoring container
pct set 103 --features nesting=1,keyctl=1

# Enable GPU device passthrough for Jellyfin (hardware transcoding)
pct set 105 --features nesting=1,keyctl=1
pct set 105 --dev0 /dev/dri/card1,gid=44
pct set 105 --dev1 /dev/dri/renderD128,gid=993

# Mount host media directory into Jellyfin container
mkdir -p /Media
pct set 105 --mp0 /Media,mp=/Media
```

## License

[MIT](LICENSE)
