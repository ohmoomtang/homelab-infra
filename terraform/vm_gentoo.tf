resource "proxmox_virtual_environment_vm" "gentoo" {
  name        = "gentoo"
  description = "Gentoo Linux - managed by Terraform"
  tags        = ["gentoo", "terraform"]
  node_name   = var.proxmox_node
  vm_id       = 181
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = 2048
  }
  disk {
    datastore_id = "local-zfs"
    size         = 20
    interface    = "scsi0"
  }
  cdrom {
    file_id   = "local:iso/gentoo-install-amd64-minimal-20260531T160106Z.iso"
    interface = "ide2"
  }
  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw"
    type         = "4m"
  }
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  vga {
    type   = "virtio"
    memory = 16
  }
  operating_system {
    type = "l26"
  }
  bios       = "ovmf"
  boot_order = ["ide2", "scsi0"]
}
