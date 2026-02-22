# Introduction

This repository contains code for my homelab, currently consisting of two Lenovo M920q nodes:

1. 6C i5-8500T CPU, 16 GB RAM, 256 GB SSD.
2. 6C i5-8500T CPU, 32 GB RAM, 256 GB SSD.

Using Proxmox VE, multiple VMs are provisioned on these nodes to run a K3s Kubernetes cluster.

## Repository Structure

### Terraform
- `terraform/proxmox/` — Terraform configuration for provisioning VMs on Proxmox hosts using the `bpg/proxmox` provider.
  - See `proxmox/README.md` for usage.

### Ansible
- `ansible/k3s/` — Ansible playbooks and roles for installing and managing K3s clusters on the VMs.
  - `install-k3s.yaml` — Bootstraps the K3s cluster (control plane + workers).
  - `install-prereqs.yaml` — Installs additional packages on existing VMs without reprovisioning.
  - `uninstall-k3s.yaml` — Tears down the cluster.
  - See `k3s/README.md` for usage.

### Kubernetes
- `kubernetes/bootstrap/` — Bootstrap configuration for cluster initialization.
  - ArgoCD setup for GitOps-based cluster management (ApplicationSets for `core` and `apps`).
- `kubernetes/core/` — Core infrastructure components:
  - **cert-manager** — TLS certificate management with Let's Encrypt.
  - **CloudNativePG** — PostgreSQL operator for application databases.
  - **databases** — Shared PostgreSQL cluster (`postgres-shared`) for multiple apps.
  - **MetalLB** — Bare-metal LoadBalancer (installation + IP pool config).
  - **monitoring** — Cluster monitoring stack (kube-prometheus-stack).
  - **NFS provisioner** — Dynamic NFS-backed PersistentVolumes.
  - **Sealed Secrets** — Encrypted secrets safe to commit to Git.
  - **Traefik** — Ingress controller and TLS configuration.
- `kubernetes/apps/` — Application deployments:
  - Home Assistant, Homepage, HortusFox, Immich, Jellyfin, Linkding, Mealie, Paperless-ngx, Vaultwarden, Vikunja.