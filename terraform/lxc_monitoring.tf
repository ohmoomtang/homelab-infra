resource "proxmox_virtual_environment_container" "monitoring" {
  description = "Grafana and Loki Monitoring - Managed by Terraform"
  tags        = ["utility", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 103

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 0
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
    size         = 20
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  start_on_boot = true
}
