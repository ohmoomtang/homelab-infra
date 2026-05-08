resource "proxmox_virtual_environment_container" "jellyfin" {
  description = "Jellyfin - Managed by Terraform"
  tags        = ["media", "terraform"]

  node_name = var.proxmox_node
  vm_id     = 105

  cpu {
    cores = 4
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
    hostname = "jellyfin"

    ip_config {
      ipv4 {
        address = "192.168.0.41/24"
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

  lifecycle {
    ignore_changes = [
      initialization,
      network_interface,
      mount_point,        # ← ตัวการหลัก
      device_passthrough, # ← workaround เดิมที่เคยทำ
      cpu,
      disk,
      features,
    ]
  }
}
