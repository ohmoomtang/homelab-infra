resource "proxmox_virtual_environment_vm" "windows_xp" {
  name        = "windowsxp"
  description = "Windows XP - managed by Terraform"
  tags        = ["windows_xp", "terraform"]
  node_name   = var.proxmox_node
  vm_id       = 181
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 1024
  }
  disk {
    datastore_id = "local-zfs"
    size         = 10
    interface    = "virtio0"
  }
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  initialization {
    datastore_id = "local-zfs"
    ip_config {
      ipv4 {
        address = "192.168.0.91/24"
        gateway = var.default_gateway
      }
    }
  }
  operating_system {
    type = "wxp"
  }
  lifecycle {
    ignore_changes = [
      initialization,
      clone,
    ]
  }
}
