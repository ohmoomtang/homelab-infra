resource "proxmox_virtual_environment_container" "ad_guard_primary" {
  description = "AdGuard Home - Primary - Managed by Terraform"
  tags        = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 100

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
    swap      = 0
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
        gateway = var.deafult_gateway
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
  tags        = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 101

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
    swap      = 0
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
