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
    ├── AdGuard Primary      192.168.0.84  (DNS, Ad-blocking)
    ├── AdGuard Secondary    192.168.0.85  (DNS, Ad-blocking)
    ├── AdGuard Sync         192.168.0.83  (Config Sync)
    ├── Monitoring           192.168.0.81  (Grafana + Loki + Prometheus)
    ├── Uptime Kuma          192.168.0.82  (Uptime Monitoring)
    ├── RabbitMQ             192.168.0.21  (Message Broker)
    ├── Supabase             192.168.0.22  (Backend Platform)
    ├── Jellyfin             192.168.0.41  (Media Server)
    ├── OpenNotebookLM       192.168.0.71  (AI Notebook)
    └── Vert                 192.168.0.72  (File Converter)
```

All containers run as unprivileged LXC on a ZFS storage backend (`local-zfs`), bridged on `vmbr0` with static IPs in the `192.168.0.0/24` subnet.

## Stack

| Category                 | Tools                            |
| ------------------------ | -------------------------------- |
| Hypervisor               | Proxmox VE                       |
| IaC                      | Terraform (bpg/proxmox ~> 0.76)  |
| Configuration Management | Ansible                          |
| DNS & Ad-blocking        | AdGuard Home                     |
| Monitoring               | Grafana, Prometheus, Loki        |
| Log/Metrics Collection   | Grafana Alloy                    |
| Uptime Monitoring        | Uptime Kuma                      |
| Media                    | Jellyfin                         |
| Message Broker           | RabbitMQ                         |
| Backend Platform         | Supabase (self-hosted via CLI)   |
| AI Notebook              | OpenNotebookLM                   |
| File Converter           | Vert                             |

## Prerequisites

- Proxmox VE installed and accessible via API
- Terraform >= 1.2
- Ansible >= 2.13
- Python 3.x
- `community.docker` and `grafana.grafana` Ansible collections

```bash
ansible-galaxy collection install community.docker grafana.grafana
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

Sensitive credentials are stored in per-role vault files. Encrypt each one before running playbooks:

```bash
ansible-vault encrypt ansible/roles/monitoring/vault.yml
ansible-vault encrypt ansible/roles/adguard-sync/vault.yml
ansible-vault encrypt ansible/roles/rabbitmq/vault.yml
ansible-vault encrypt ansible/roles/opennotebooklm/vars/vault.yml
```

### 5. Run Ansible Playbooks

Run the base playbook first, then service-specific playbooks:

```bash
cd ansible

# Harden and configure all hosts
ansible-playbook playbooks/base.yml

# Deploy services
ansible-playbook playbooks/adguard.yml
ansible-playbook playbooks/adguardsync.yml
ansible-playbook playbooks/monitoring.yml
ansible-playbook playbooks/uptimekuma.yml
ansible-playbook playbooks/rabbitmq.yml
ansible-playbook playbooks/jellyfin.yml
ansible-playbook playbooks/supabase.yml
ansible-playbook playbooks/opennotebooklm.yml
ansible-playbook playbooks/vert.yml

# Deploy Alloy metrics/log agent on all Debian hosts
ansible-playbook playbooks/alloy.yml
```

> **Note:** Vault-encrypted files require `--ask-vault-pass` or a vault password file.

## Repository Structure

```
homelab-infra/
├── terraform/
│   ├── main.tf                  # 10 LXC container definitions
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   ├── hosts.yml            # Hosts grouped by function
    │   └── group_vars/
    │       └── all.yml          # Global vars (user, SSH key, timezone)
    ├── playbooks/
    │   ├── base.yml
    │   ├── adguard.yml
    │   ├── adguardsync.yml
    │   ├── monitoring.yml
    │   ├── uptimekuma.yml
    │   ├── rabbitmq.yml
    │   ├── jellyfin.yml
    │   ├── supabase.yml
    │   ├── opennotebooklm.yml
    │   ├── vert.yml
    │   └── alloy.yml
    └── roles/
        ├── base/                # Ubuntu/Debian hardening + admin user
        ├── base-alpine/         # Alpine hardening + admin user
        ├── docker/              # Docker CE on Ubuntu
        ├── docker-alpine/       # Docker on Alpine
        ├── adguard/             # AdGuard Home container
        ├── adguard-sync/        # AdGuard config sync (cron every 10m)
        ├── monitoring/          # Grafana + Prometheus + Loki via Compose
        ├── uptimekuma/          # Uptime Kuma via Compose
        ├── rabbitmq/            # RabbitMQ with management UI
        ├── jellyfin/            # Jellyfin with GPU passthrough
        ├── supabase/            # Supabase via CLI + systemd
        ├── opennotebooklm/      # OpenNotebookLM + SurrealDB via Compose
        ├── vert/                # Vert file converter via Compose
        └── alloy/               # Grafana Alloy agent (Debian hosts only)
```

## IP Addressing Scheme

| Range        | Category             |
| ------------ | -------------------- |
| 192.168.0.2x | Middleware / Backend |
| 192.168.0.4x | Media                |
| 192.168.0.7x | General apps         |
| 192.168.0.8x | Utility / Network    |

## LXC Container Inventory

| VM ID | Hostname          | IP             | CPU | RAM   | OS      |
| ----- | ----------------- | -------------- | --- | ----- | ------- |
| 100   | adguard-primary   | 192.168.0.84   | 1   | 1 GB  | Alpine  |
| 101   | adguard-secondary | 192.168.0.85   | 1   | 1 GB  | Alpine  |
| 102   | adguard-sync      | 192.168.0.83   | 1   | 256 MB| Ubuntu  |
| 103   | monitoring        | 192.168.0.81   | 2   | 2 GB  | Ubuntu  |
| 104   | uptime-kuma       | 192.168.0.82   | 1   | 512 MB| Ubuntu  |
| 105   | jellyfin          | 192.168.0.41   | 4   | 2 GB  | Ubuntu  |
| 106   | rabbitmq          | 192.168.0.21   | 1   | 2 GB  | Ubuntu  |
| 107   | opennotebooklm    | 192.168.0.71   | 2   | 4 GB  | Ubuntu  |
| 108   | vert              | 192.168.0.72   | 1   | 512 MB| Ubuntu  |
| 109   | supabase          | 192.168.0.22   | 4   | 8 GB  | Ubuntu  |

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
