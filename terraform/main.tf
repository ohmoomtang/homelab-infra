terraform {
    required_version = ">= 1.2"
    required_providers {
        proxmox = {
            source  = "bpg/proxmox"
            version = "~> 0.76"
        }  
    }
}

locals {
  ssh_public_key = [var.ssh_public_key]
}

provider "proxmox" {
    endpoint  = var.proxmox_pve_endpoint
    api_token = var.proxmox_pve_api_token
    insecure  = true
}

resource "proxmox_virtual_environment_container" "ad_guard_primary" {
  description = "AdGuard Home - Primary - Managed by Terraform"
  tags = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 100

  cpu{
    cores = 1
  }

  memory {
    dedicated = 1024
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "adguard-primary"

    ip_config {
      ipv4 {
        address = "192.168.0.84/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 2
  }

  operating_system {
    template_file_id = "local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz"
    type             = "alpine"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "ad_guard_secondary" {
  description = "AdGuard Home - Secondary - Managed by Terraform"
  tags = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 101

  cpu{
    cores = 1
  }

  memory {
    dedicated = 1024
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "adguard-secondary"

    ip_config {
      ipv4 {
        address = "192.168.0.85/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 2
  }

  operating_system {
    template_file_id = "local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz"
    type             = "alpine"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "ad_guard_sync" {
  description = "AdGuard Home Sync - Managed by Terraform"
  tags = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 102

  cpu{
    cores = 1
  }

  memory {
    dedicated = 256
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "adguard-sync"

    ip_config {
      ipv4 {
        address = "192.168.0.83/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 2
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "monitoring" {
  description = "Grafana and Loki Monitoring - Managed by Terraform"
  tags = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 103

  cpu{
    cores = 2
  }

  memory {
    dedicated = 2048
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
# keyctl และ device_passthrough ต้อง set manual via pct
# pct set 103 --features nesting=1,keyctl=1
# pct set 105 --features nesting=1,keyctl=1,dev0=/dev/dri/card1
    # keyctl  = true
  }

  initialization {
    hostname = "monitoring"

    ip_config {
      ipv4 {
        address = "192.168.0.81/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 20
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "uptime_kuma" {
  description = "Uptime Kuma - Managed by Terraform"
  tags = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 104

  cpu{
    cores = 1
  }

  memory {
    dedicated = 512
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "uptime-kuma"

    ip_config {
      ipv4 {
        address = "192.168.0.82/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 4
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "jellyfin" {
  description = "Jellyfin - Managed by Terraform"
  tags = ["media", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 105

  cpu{
    cores = 4
  }

  memory {
    dedicated = 2048
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
# keyctl และ device_passthrough ต้อง set manual via pct
# pct set 103 --features nesting=1,keyctl=1
# pct set 105 --features nesting=1,keyctl=1,dev0=/dev/dri/card1
    # keyctl  = true
  }

  initialization {
    hostname = "jellyfin"

    ip_config {
      ipv4 {
        address = "192.168.0.41/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 16
  }
  # device passthrough แยกต่างหาก
  #pct set 105 --dev0 /dev/dri/card1,gid=44
  #pct set 105 --dev1 /dev/dri/renderD128,gid=993  
  # device_passthrough {
  #   path = "/dev/dri/card1"
  #   gid  = 44
  # }

  # device_passthrough {
  #   path = "/dev/dri/renderD128"
  #   gid  = 993
  # }

  # mount_point ต้อง set manual via pct
  # pct set 105 --mp0 /Media,mp=/Media
  # mount_point {
  #   volume = "/Media/"
  #   path   = "/Media/"
  # }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "rabbitmq" {
  description = "RabbitMQ - Managed by Terraform"
  tags = ["middleware", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 106

  cpu{
    cores = 1
  }

  memory {
    dedicated = 2048
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "rabbitmq"

    ip_config {
      ipv4 {
        address = "192.168.0.21/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 8
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "open_notebook_lm" {
  description = "OpenNotebookLM - Managed by Terraform"
  tags = ["general-app", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 107

  cpu{
    cores = 2
  }

  memory {
    dedicated = 4096
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
# keyctl และ device_passthrough ต้อง set manual via pct
# pct set 103 --features nesting=1,keyctl=1
# pct set 105 --features nesting=1,keyctl=1,dev0=/dev/dri/card1
    # keyctl  = true
  }

  initialization {
    hostname = "opennotebooklm"

    ip_config {
      ipv4 {
        address = "192.168.0.71/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 10
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "vert" {
  description = "Vert - Managed by Terraform"
  tags = ["general-app", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 108

  cpu{
    cores = 1
  }

  memory {
    dedicated = 512
    swap = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "vert"

    ip_config {
      ipv4 {
        address = "192.168.0.72/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 4
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}

resource "proxmox_virtual_environment_container" "supabase" {
  description = "Supabase (Local) - Managed by Terraform"
  tags = ["backend", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 109

  cpu{
    cores = 4
  }

  memory {
    dedicated = 8192
    swap = 2048
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "supabase"

    ip_config {
      ipv4 {
        address = "192.168.0.22/24"
        gateway = "192.168.0.1"
      }
    }

    user_account {
      password = var.default_lxc_root_password
      keys     = local.ssh_public_key
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 50
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}