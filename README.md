# Introduction

This repository contains code for my homelab,currently consisting of two  Lenovo M920q nodes


1. 6C i5-8500T CPU, 16 GB RAM, 256 GB SSD.
2. 6C i5-8500T CPU, 32 GB RAM, 256 GB SSD.

Using proxmox, multiple VMs will be run on this node for a k3s cluster.


## Repository structure

### Terraform
- `terraform/proxmox/` - Terraform configuration for provisioning VMs on Proxmox hosts using the bpg/proxmox provider

### Ansible
- `ansible/k3s/` - Ansible playbooks and roles for installing and managing k3s clusters on the VMs
  - Installation and uninstallation playbooks
  - Roles for k3s server and agent node configuration

### Kubernetes
- `kubernetes/bootstrap/` - Bootstrap configuration for cluster initialization
  - ArgoCD setup for GitOps-based cluster management
- `kubernetes/core/` - Core infrastructure components
  - CloudNativePG for PostgreSQL operators
  - MetalLB for load balancing
  - NFS provisioner for persistent storage
  - Sealed Secrets for encrypted secret management
- `kubernetes/apps/` - Application deployments
  - HortusFox, Immich, Mealie, Vaultwarden, and other self-hosted applications