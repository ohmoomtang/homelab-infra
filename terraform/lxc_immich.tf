resource "proxmox_virtual_environment_container" "immich" {
  description = "Immich - Managed by Terraform"
  tags        = ["media", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 111

  cpu {
    cores = 4
    limit = 200 # จำกัดที่ 2 cores worth
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
    hostname = "immich"

    ip_config {
      ipv4 {
        address = "192.168.0.42/24"
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
    size         = 8
  }

  mount_point {
    volume = "/mnt/data/photos"
    path   = "/photos"
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}
