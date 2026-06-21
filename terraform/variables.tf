variable "proxmox_pve_endpoint" {
  type        = string
  description = "Endpoint for Proxmox PVE"

  validation {
    condition     = startswith(var.proxmox_pve_endpoint, "https://")
    error_message = "Endpoint must start with https://"
  }
}

variable "proxmox_pve_api_token" {
  type        = string
  description = "API Token for Proxmox PVE"
  sensitive   = true

  validation {
    condition     = can(regex("^.+@.+!.+=.+$", var.proxmox_pve_api_token))
    error_message = "API Token format must be user@realm!tokenid=secret"
  }
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve1"
}

variable "default_lxc_root_password" {
  type        = string
  description = "Default root password for each Proxmox LXC"
  sensitive   = true

  validation {
    condition     = length(var.default_lxc_root_password) >= 8
    error_message = "Password must be at least 8 characters"
  }
}

variable "default_gateway" {
  type        = string
  description = "Default Gateway (Router -> ISP) IP Address"
  default     = "192.168.0.1"
}

#K3s
variable "k3s_ubuntu_template_vmid" {
  type        = number
  description = "Ubuntu VM template for K3s master and worker nodes"
  default     = 9000
}

variable "k3s_node_password" {
  type        = string
  description = "Password for each K3s node"
  sensitive   = true
}

variable "ssh_public_key" {
  type      = string
  sensitive = false
}

