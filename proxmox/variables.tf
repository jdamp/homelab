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

variable "proxmox_node" {
  description = "Name of the Proxmox node to deploy VMs on"
  type        = string
  default     = "pve"
}

# VM Template Settings
variable "template_name" {
  description = "Name of the VM template to clone (must be created in Proxmox first)"
  type        = string
  default     = "ubuntu-cloud-template"
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

# IP Configuration
variable "control_plane_ip" {
  description = "IP address for control plane node"
  type        = string
  default     = "192.168.1.10"
}

variable "worker1_ip" {
  description = "IP address for worker node 1"
  type        = string
  default     = "192.168.1.20"
}

variable "worker2_ip" {
  description = "IP address for worker node 2"
  type        = string
  default     = "192.168.1.21"
}
