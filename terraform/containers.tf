# Single source of truth for every standard LXC container.
# Each entry maps to one module.lxc["<key>"] instance.
# vm_id / ip live here so collisions are visible at a glance.
#
# Note: jellyfin is intentionally NOT here. It needs a per-resource
# lifecycle{ ignore_changes } block (manual pct mount_point / device
# passthrough) which Terraform does not allow to be parameterised in a
# module, so it stays in lxc_jellyfin.tf.

locals {
  containers = {
    "adguard-primary" = {
      vmid        = 100
      hostname    = "adguard-primary"
      ip          = "192.168.0.84"
      cores       = 1
      memory      = 1024
      disk_size   = 2
      os_type     = "alpine"
      tags        = ["utility", "terraform"]
      description = "AdGuard Home - Primary - Managed by Terraform"
    }
    "adguard-secondary" = {
      vmid        = 101
      hostname    = "adguard-secondary"
      ip          = "192.168.0.85"
      cores       = 1
      memory      = 1024
      disk_size   = 2
      os_type     = "alpine"
      tags        = ["utility", "terraform"]
      description = "AdGuard Home - Secondary - Managed by Terraform"
    }
    "adguard-sync" = {
      vmid        = 102
      hostname    = "adguard-sync"
      ip          = "192.168.0.83"
      cores       = 2
      memory      = 1024
      disk_size   = 2
      os_type     = "ubuntu"
      tags        = ["utility", "terraform"]
      description = "AdGuard Home Sync - Managed by Terraform"
    }
    "monitoring" = {
      vmid        = 103
      hostname    = "monitoring"
      ip          = "192.168.0.81"
      cores       = 2
      memory      = 2048
      disk_size   = 20
      os_type     = "ubuntu"
      tags        = ["utility", "terraform"]
      description = "Grafana and Loki Monitoring - Managed by Terraform"
    }
    "uptime-kuma" = {
      vmid        = 104
      hostname    = "uptime-kuma"
      ip          = "192.168.0.82"
      cores       = 1
      memory      = 1024
      disk_size   = 4
      os_type     = "ubuntu"
      tags        = ["utility", "terraform"]
      description = "Uptime Kuma - Managed by Terraform"
    }
    "vert" = {
      vmid        = 108
      hostname    = "vert"
      ip          = "192.168.0.52"
      cores       = 1
      memory      = 512
      disk_size   = 4
      os_type     = "ubuntu"
      tags        = ["general-app", "terraform"]
      description = "Vert - Managed by Terraform"
    }
    "supabase" = {
      vmid        = 109
      hostname    = "supabase"
      ip          = "192.168.0.22"
      cores       = 4
      memory      = 8192
      swap        = 2048
      disk_size   = 50
      os_type     = "ubuntu"
      tags        = ["backend", "terraform"]
      description = "Supabase (Local) - Managed by Terraform"
    }
    "samba" = {
      vmid        = 110
      hostname    = "samba"
      ip          = "192.168.0.86"
      cores       = 1
      memory      = 256
      disk_size   = 4
      os_type     = "alpine"
      tags        = ["utility", "terraform"]
      description = "Samba - Managed by Terraform"
      mount_points = [
        { volume = "/mnt/data/shares", path = "/shares" },
      ]
    }
    "immich" = {
      vmid        = 111
      hostname    = "immich"
      ip          = "192.168.0.42"
      cores       = 4
      cpu_limit   = 200
      memory      = 4096
      disk_size   = 8
      os_type     = "ubuntu"
      tags        = ["media", "terraform"]
      description = "Immich - Managed by Terraform"
      mount_points = [
        { volume = "/mnt/data/photos", path = "/photos" },
      ]
    }
    "it-tools" = {
      vmid        = 112
      hostname    = "ittools"
      ip          = "192.168.0.87"
      cores       = 1
      memory      = 256
      disk_size   = 4
      os_type     = "alpine"
      tags        = ["utility", "terraform"]
      description = "IT Tools - Managed by Terraform"
    }
    "portainer" = {
      vmid        = 113
      hostname    = "portainer"
      ip          = "192.168.0.89"
      cores       = 1
      memory      = 1024
      disk_size   = 8
      os_type     = "ubuntu"
      tags        = ["utility", "terraform"]
      description = "Portainer - Managed by Terraform"
    }
    "sonarqube" = {
      vmid        = 114
      hostname    = "sonarqube"
      ip          = "192.168.0.23"
      cores       = 2
      memory      = 4096
      disk_size   = 20
      os_type     = "ubuntu"
      tags        = ["devtools", "terraform"]
      description = "Sonarqube - Managed by Terraform"
    }
    "github-action" = {
      vmid        = 115
      hostname    = "githubaction"
      ip          = "192.168.0.24"
      cores       = 2
      memory      = 2048
      disk_size   = 20
      os_type     = "ubuntu"
      tags        = ["devtools", "terraform"]
      description = "GitHub Action - Managed by Terraform"
    }
    "traefik" = {
      vmid        = 116
      hostname    = "traefik"
      ip          = "192.168.0.90"
      cores       = 1
      memory      = 512
      disk_size   = 4
      os_type     = "ubuntu"
      tags        = ["utility", "terraform"]
      description = "Traefik - Managed by Terraform"
    }
    "nextjs-blog" = {
      vmid        = 117
      hostname    = "blog"
      ip          = "192.168.0.11"
      cores       = 2
      memory      = 2048
      disk_size   = 8
      os_type     = "ubuntu"
      tags        = ["website", "terraform"]
      description = "Next.js - Blog - Managed by Terraform"
    }

    "umami-realbreakfast" = {
      vmid        = 118
      hostname    = "umami-realbreakfast"
      ip          = "192.168.0.25"
      cores       = 1
      memory      = 1024
      disk_size   = 4
      os_type     = "ubuntu"
      tags        = ["analytics", "terraform"]
      description = "Umami - Web Analytics - realbreakfast.co - Managed by Terraform"
    }

    "nextjs-realbreakfast" = {
      vmid        = 119
      hostname    = "realbreakfast"
      ip          = "192.168.0.12"
      cores       = 2
      memory      = 4096
      disk_size   = 20
      os_type     = "ubuntu"
      tags        = ["website", "terraform"]
      description = "realbreakfast.co - Web App - Managed by Terraform"
    }
    "rustfs" = {
      vmid        = 120
      hostname    = "rustfs"
      ip          = "192.168.0.26"
      cores       = 2
      memory      = 2048
      disk_size   = 8
      os_type     = "ubuntu"
      tags        = ["backend", "terraform"]
      description = "RustFS - Managed by Terraform"
    }
  }
}

module "lxc" {
  source   = "./modules/lxc_container"
  for_each = local.containers

  vmid         = each.value.vmid
  hostname     = each.value.hostname
  description  = each.value.description
  ip           = each.value.ip
  cores        = each.value.cores
  cpu_limit    = try(each.value.cpu_limit, null)
  memory       = each.value.memory
  swap         = try(each.value.swap, 0)
  disk_size    = each.value.disk_size
  os_type      = each.value.os_type
  tags         = each.value.tags
  mount_points = try(each.value.mount_points, [])

  # shared / global settings
  node_name = var.proxmox_node
  gateway   = var.default_gateway
  password  = var.default_lxc_root_password
  ssh_keys  = local.ssh_public_key
}
