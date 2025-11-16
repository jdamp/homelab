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
}

variable "cloud_image_filename" {
  description = "Filename for the cloud image (must have .qcow2 extension for import)"
  type        = string
}

variable "cloud_image_nodes" {
  description = "List of Proxmox nodes to download the cloud image to"
  type        = list(string)
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

# SSH Settings
variable "ssh_user" {
  description = "SSH user for VM access"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file for VM access"
  type        = string
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
}
