locals {
  template_by_os = {
    ubuntu = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    alpine = "local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz"
  }

  template_file_id = coalesce(var.template_file_id, local.template_by_os[var.os_type])
}

resource "proxmox_virtual_environment_container" "this" {
  description = var.description
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vmid

  cpu {
    cores = var.cores
    limit = var.cpu_limit
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  # newer linux distributions require unprivileged user namespaces
  unprivileged = var.unprivileged
  features {
    nesting = var.nesting
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = "${var.ip}/24"
        gateway = var.gateway
      }
    }

    user_account {
      password = var.password
      keys     = var.ssh_keys
    }
  }

  network_interface {
    name   = var.network_name
    bridge = var.bridge
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume = mount_point.value.volume
      path   = mount_point.value.path
    }
  }

  operating_system {
    template_file_id = local.template_file_id
    type             = var.os_type
  }

  start_on_boot = var.start_on_boot
}
