# Kubernetes

This folder contains Kubernetes manifests for this homelab, organized for GitOps using Argo CD.

## Layout

- `bootstrap/`: one-time bootstrap to install Argo CD and create the ApplicationSet that tracks this repo.
  - See `bootstrap/README.md` for the install commands.
- `core/`: cluster-wide platform components (operators, networking, storage, secrets).
  - Generally applied via Kustomize or a small Helm “wrapper” chart.
- `apps/`: application workloads.
  - Still in progress.

## Notable components

- `core/sealed-secrets/`: Sealed Secrets controller (for storing secrets safely in Git).
- `core/metallb-install/` and `core/metallb-config/`: MetalLB installation and configuration.
- `core/nfs-provisioner/`: NFS dynamic provisioning (default StorageClass).
- `core/cloudnative-pg/`: CloudNativePG operator (Postgres clusters for apps).
