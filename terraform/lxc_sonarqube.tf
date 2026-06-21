resource "proxmox_virtual_environment_container" "sonarqube" {
  description = "Sonarqube - Managed by Terraform"
  tags        = ["devtools", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 114

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
    swap      = 0
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "sonarqube"

    ip_config {
      ipv4 {
        address = "192.168.0.23/24"
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
    size         = 20
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}
