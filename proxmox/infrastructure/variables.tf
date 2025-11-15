# Proxmox Connection Settings
variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.local:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., root@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (set to true for self-signed certificates)"
  type        = bool
  default     = true
}

# VM Template Settings
variable "template_vm_id" {
  description = "VM ID of the template to clone (must be created in Proxmox first)"
  type        = number
}

variable "template_storage" {
  description = "Storage location for VM disks"
  type        = string
  default     = "local-lvm"
}

# Network Settings
variable "network_bridge" {
  description = "Network bridge to use for VMs"
  type        = string
  default     = "vmbr0"
}

variable "network_model" {
  description = "Network card model"
  type        = string
  default     = "virtio"
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.1.1"
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "8.8.8.8"
}

# SSH Settings
variable "ssh_user" {
  description = "SSH user for VM access"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

# K3s Cluster Configuration
variable "cluster_name" {
  description = "Name prefix for the k3s cluster"
  type        = string
  default     = "k3s"
}

# Control Plane Nodes Configuration
variable "control_plane_nodes" {
  description = "List of control plane node configurations"
  type = list(object({
    name         = string
    proxmox_node = string
    cpu_cores    = number
    memory_mb    = number
    disk_size_gb = number
    ip_address   = string
  }))
  default = [
    {
      name         = "control-01"
      proxmox_node = "pve"
      cpu_cores    = 2
      memory_mb    = 4096
      disk_size_gb = 40
      ip_address   = "192.168.1.10"
    }
  ]
}

# Worker Nodes Configuration
variable "worker_nodes" {
  description = "List of worker node configurations"
  type = list(object({
    name         = string
    proxmox_node = string
    cpu_cores    = number
    memory_mb    = number
    disk_size_gb = number
    ip_address   = string
  }))
  default = [
    {
      name         = "worker-01"
      proxmox_node = "pve"
      cpu_cores    = 2
      memory_mb    = 5120
      disk_size_gb = 60
      ip_address   = "192.168.1.20"
    },
    {
      name         = "worker-02"
      proxmox_node = "pve"
      cpu_cores    = 2
      memory_mb    = 5120
      disk_size_gb = 60
      ip_address   = "192.168.1.21"
    }
  ]
}
