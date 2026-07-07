terraform {
  required_version = ">= 1.2"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.76"
    }
  }
}

locals {
  ssh_public_key = [var.ssh_public_key]
}

provider "proxmox" {
  endpoint  = var.proxmox_pve_endpoint
  api_token = var.proxmox_pve_api_token
  insecure  = true
}
