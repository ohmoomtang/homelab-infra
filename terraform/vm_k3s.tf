locals {
  k3s_nodes = {
    "control-plane" = { vmid = 171, ip = "192.168.0.71", cores = 2, memory = 4096, description = "K3s control plane node - managed by Terraform", tags = ["k3s", "control-plane", "terraform"] }
    "worker-01"     = { vmid = 172, ip = "192.168.0.72", cores = 2, memory = 4096, description = "K3s worker node 01  - managed by Terraform", tags = ["k3s", "worker", "terraform"] }
    "worker-02"     = { vmid = 173, ip = "192.168.0.73", cores = 2, memory = 4096, description = "K3s worker node 02  - managed by Terraform", tags = ["k3s", "worker", "terraform"] }
  }
}

resource "proxmox_virtual_environment_vm" "k3s_nodes" {
  for_each    = local.k3s_nodes
  name        = "k3s-${each.key}"
  description = each.value.description
  tags        = each.value.tags
  node_name   = var.proxmox_node
  vm_id       = each.value.vmid
  clone {
    vm_id = var.k3s_ubuntu_template_vmid
    full  = true
  }
  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = each.value.memory
  }
  disk {
    datastore_id = "local-zfs"
    size         = 32
    interface    = "scsi0"
  }
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  initialization {
    datastore_id = "local-zfs"
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.default_gateway
      }
    }
    user_account {
      username = "ubuntu"
      password = var.k3s_node_password
      keys     = local.ssh_public_key
    }
  }
  operating_system {
    type = "l26"
  }
  lifecycle {
    ignore_changes = [
      initialization,
      clone,
    ]
  }
}
