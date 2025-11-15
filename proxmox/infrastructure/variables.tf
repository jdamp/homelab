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

# Cloud Image Settings
variable "cloud_image_url" {
  description = "URL to download the cloud image from"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "cloud_image_filename" {
  description = "Filename for the cloud image (must have .qcow2 extension for import)"
  type        = string
  default     = "jammy-server-cloudimg-amd64.qcow2"
}

variable "cloud_image_datastore" {
  description = "Datastore for the cloud image file"
  type        = string
  default     = "local"
}

variable "cloud_image_node" {
  description = "Proxmox node to download the cloud image to"
  type        = string
  default     = "pve"
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

variable "ssh_public_key_path" {
  description = "Path to SSH public key file for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# K3s Cluster Configuration
variable "cluster_name" {
  description = "Name prefix for the k3s cluster"
  type        = string
  default     = "k3s"
}

# K3s Nodes Configuration (Control Plane and Workers)
variable "k3s_nodes" {
  description = "List of K3s nodes (control plane and workers)"
  type = list(object({
    name         = string
    description  = string
    proxmox_node = string
    cpu_cores    = number
    memory_mb    = number
    disk_size_gb = number
    ip_address   = string
  }))
  default = [
    {
      name         = "control-01"
      description  = "K3s Control Plane Node 1"
      proxmox_node = "pve"
      cpu_cores    = 2
      memory_mb    = 4096
      disk_size_gb = 40
      ip_address   = "192.168.1.10"
    },
    {
      name         = "worker-01"
      description  = "K3s Worker Node 1"
      proxmox_node = "pve"
      cpu_cores    = 2
      memory_mb    = 5120
      disk_size_gb = 60
      ip_address   = "192.168.1.20"
    },
    {
      name         = "worker-02"
      description  = "K3s Worker Node 2"
      proxmox_node = "pve"
      cpu_cores    = 2
      memory_mb    = 5120
      disk_size_gb = 60
      ip_address   = "192.168.1.21"
    }
  ]
}
