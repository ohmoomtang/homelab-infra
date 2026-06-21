resource "proxmox_virtual_environment_container" "it_tools" {
  description = "IT Tools - Managed by Terraform"
  tags        = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 112

  cpu {
    cores = 1
  }

  memory {
    dedicated = 256
    swap      = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "ittools"

    ip_config {
      ipv4 {
        address = "192.168.0.87/24"
        gateway = var.default_gateway
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
    template_file_id = "local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz"
    type             = "alpine"
  }

  start_on_boot = true
}
