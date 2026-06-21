# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Terraform

```bash
cd terraform
terraform init          # first time or after provider changes
terraform plan          # preview changes
terraform apply         # provision/update resources
terraform destroy       # tear down (destructive — confirm with user first)
```

All secrets go in `terraform.tfvars` (gitignored). Use `terraform.tfvars.example` as the template. The provider is `bpg/proxmox ~> 0.76` connecting to Proxmox PVE via API token. `insecure = true` is intentional (self-signed cert on the local PVE host).

Each LXC container has its own `.tf` file (e.g. `lxc_monitoring.tf`). K3s VMs are in `vm_k3s.tf` and use `for_each` over a `locals` map. `main.tf` only contains provider and backend config.

## Ansible

```bash
cd ansible

# Run a playbook against the homelab LXC inventory
ansible-playbook -i inventories/homelab playbooks/<name>.yml --ask-vault-pass

# Run a playbook against the K3s inventory
ansible-playbook -i inventories/k3s playbooks/<name>.yml --ask-vault-pass

# Target a single host
ansible-playbook -i inventories/homelab playbooks/<name>.yml --limit <hostname> --ask-vault-pass

# Test connectivity
ansible -i inventories/homelab all -m ping
```

**Note:** `ansible.cfg` still points `inventory = inventory/hosts.yml` (the old path). Always pass `-i inventories/homelab` or `-i inventories/k3s` explicitly on the command line to override it.

### Vault files

Sensitive credentials are stored in per-role vault files, not a single global vault:

| Role           | Vault file                            |
| -------------- | ------------------------------------- |
| adguard-sync   | `roles/adguard-sync/vault.yml`        |
| monitoring     | `roles/monitoring/vault.yml`          |
| rabbitmq       | `roles/rabbitmq/vault.yml`            |
| opennotebooklm | `roles/opennotebooklm/vars/vault.yml` |
| k3s inventory  | `inventories/k3s/vault.yml`           |

Encrypt a new vault file: `ansible-vault encrypt <path>`. Edit in place: `ansible-vault edit <path>`.

### Role structure

Each service follows the pattern: `base` (or `base-alpine`) → `docker` (or `docker-alpine`) → service role. Alpine-based containers (AdGuard primary/secondary) use `base-alpine` + `docker-alpine`. The `alloy` role uses the `grafana.grafana.alloy` community collection and only runs on Debian hosts.

## Architecture

Two distinct workloads share the same Proxmox node and subnet:

1. **LXC containers** — unprivileged, ZFS-backed, managed via `inventories/homelab`. Groups: `utility`, `middleware`, `backend`, `media`, `general_app` (all under the parent `lxc` group). Used by `update_lxc.yml` for rolling updates.

2. **K3s VMs** — cloned from Ubuntu template VMID 9000, managed via `inventories/k3s`. Groups: `server` (control plane at `192.168.0.71`) and `agent` (workers at `.72`, `.73`).

The monitoring stack (Grafana + Prometheus + Loki on `192.168.0.81`) is the central observability hub. Grafana Alloy runs on every Debian LXC host as a sidecar agent, scraping metrics on port `12345` and forwarding to Prometheus/Loki.

## Required Ansible collections

```bash
ansible-galaxy collection install community.docker grafana.grafana community.general
```

## Typo to be aware of

`var.default_gateway` (not `default_gateway`) is used throughout the Terraform VM/LXC resources — this is the existing variable name in `variables.tf`, do not "fix" it without updating all references.
