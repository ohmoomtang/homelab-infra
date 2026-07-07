variable "vmid" {
  description = "Proxmox VM/CT id"
  type        = number
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "description" {
  description = "Container description shown in the Proxmox UI"
  type        = string
}

variable "ip" {
  description = "IPv4 address without CIDR suffix (a /24 is appended)"
  type        = string
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "cpu_limit" {
  description = "Optional CPU limit (VCPU units). null = unlimited"
  type        = number
  default     = null
}

variable "memory" {
  description = "Dedicated memory in MB"
  type        = number
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
}

variable "tags" {
  description = "Proxmox tags"
  type        = list(string)
}

variable "os_type" {
  description = "Guest OS type: ubuntu or alpine"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "alpine"], var.os_type)
    error_message = "os_type must be either \"ubuntu\" or \"alpine\"."
  }
}

variable "template_file_id" {
  description = "Override the OS template file id. Defaults to the standard image for os_type."
  type        = string
  default     = null
}

variable "mount_points" {
  description = "Optional additional mount points"
  type = list(object({
    volume = string
    path   = string
  }))
  default = []
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "password" {
  description = "Root password for the container"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "List of SSH public keys for the root user"
  type        = list(string)
}

variable "datastore_id" {
  description = "Datastore for the root disk"
  type        = string
  default     = "local-zfs"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "network_name" {
  description = "Network interface name"
  type        = string
  default     = "eth0"
}

variable "nesting" {
  description = "Enable nesting feature"
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Run as unprivileged container"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start the container on host boot"
  type        = bool
  default     = true
}
