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

Standard LXC containers are defined as a single source of truth in `containers.tf`: a `locals.containers` map (vm_id, ip, spec per container) consumed by `module.lxc` (`for_each`), which wraps the reusable `modules/lxc_container` module. To add/change a container, edit the map entry — do not create a new `lxc_*.tf` file. The module supports optional `cpu_limit`, `swap`, and `mount_points`, and picks the OS template from `os_type` (`ubuntu`/`alpine`).

**Exception:** `lxc_jellyfin.tf` stays a standalone resource because it needs a `lifecycle { ignore_changes }` block (manual `pct` mount points / device passthrough), which Terraform cannot parameterise inside a module.

K3s VMs are in `vm_k3s.tf` and use `for_each` over a `locals` map. One-off VMs have their own files (`vm_gentoo.tf`, `vm_xp.tf`). `main.tf` only contains provider and backend config.

When refactoring container addresses (e.g. renaming a map key), use `terraform state mv` so existing containers are not destroyed/recreated, then confirm `terraform plan -target=module.lxc` reports **No changes**. Note: a full `terraform plan` hangs refreshing the K3s VMs (171–173) — a known, long-standing issue — so target `module.lxc` when verifying container changes.

## Ansible

```bash
cd ansible

# Provision a single service (tag = service name)
ansible-playbook -i inventories/homelab playbooks/site.yml --tags immich --ask-vault-pass

# Provision a whole category (e.g. media, utility, debian, alpine)
ansible-playbook -i inventories/homelab playbooks/site.yml --tags media --ask-vault-pass

# Provision everything
ansible-playbook -i inventories/homelab playbooks/site.yml --ask-vault-pass

# List available tags
ansible-playbook -i inventories/homelab playbooks/site.yml --list-tags

# Cross-cutting / maintenance playbooks (kept separate from site.yml)
ansible-playbook -i inventories/homelab playbooks/base.yml --ask-vault-pass        # base hardening, all LXC
ansible-playbook -i inventories/homelab playbooks/alloy.yml --ask-vault-pass       # Alloy agent, Debian LXC
ansible-playbook -i inventories/homelab playbooks/update-lxc.yml                    # rolling package updates

# K3s inventory
ansible-playbook -i inventories/k3s playbooks/<name>.yml --ask-vault-pass

# Test connectivity
ansible -i inventories/homelab all -m ping
```

All per-service provisioning lives in `playbooks/site.yml`, one tagged play per service. `ansible.cfg` now points `inventory = inventories/homelab`, but still pass `-i inventories/k3s` explicitly for the K3s cluster.

### Vault files

Sensitive credentials are stored in per-role vault files, not a single global vault:

| Role           | Vault file                            |
| -------------- | ------------------------------------- |
| adguard-sync   | `roles/adguard-sync/vault.yml`        |
| monitoring     | `roles/monitoring/vault.yml`          |
| rabbitmq       | `roles/rabbitmq/vault.yml`            |
| opennotebooklm | `roles/opennotebooklm/vault.yml`      |
| k3s inventory  | `inventories/k3s/vault.yml`           |

Encrypt a new vault file: `ansible-vault encrypt <path>`. Edit in place: `ansible-vault edit <path>`.

### Role structure

Each service follows the pattern: `base` (or `base-alpine`) → `docker` (or `docker-alpine`) → service role. Alpine-based containers (AdGuard primary/secondary) use `base-alpine` + `docker-alpine`. The `alloy` role uses the `grafana.grafana.alloy` community collection and only runs on Debian hosts. Role and playbook names use hyphens (e.g. `github-action`, not `github_action`).

## Architecture

Two distinct workloads share the same Proxmox node and subnet:

1. **LXC containers** — unprivileged, ZFS-backed, managed via `inventories/homelab`. Groups: `utility`, `middleware`, `backend`, `media`, `general_app` (all under the parent `lxc` group). Used by `update-lxc.yml` for rolling updates.

2. **K3s VMs** — cloned from Ubuntu template VMID 9000, managed via `inventories/k3s`. Groups: `server` (control plane at `192.168.0.71`) and `agent` (workers at `.72`, `.73`).

The monitoring stack (Grafana + Prometheus + Loki on `192.168.0.81`) is the central observability hub. Grafana Alloy runs on every Debian LXC host as a sidecar agent, scraping metrics on port `12345` and forwarding to Prometheus/Loki.

## Required Ansible collections

```bash
ansible-galaxy collection install community.docker grafana.grafana community.general
```

## Typo to be aware of

`var.default_gateway` (not `default_gateway`) is used throughout the Terraform VM/LXC resources — this is the existing variable name in `variables.tf`, do not "fix" it without updating all references.
