# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Homelab infrastructure running on two Lenovo M920q nodes (Proxmox VE). The repo automates VM provisioning, K3s cluster setup, and GitOps-driven application deployment.

**Stack:** Proxmox VE → Terraform → Ansible → K3s → Argo CD → applications

## Cluster Bootstrap (in order)

1. **Provision VMs:**
   ```bash
   cd terraform/proxmox && terraform apply
   ```
   Generates `terraform/proxmox/inventory.ini` consumed by Ansible.

2. **Install K3s:**
   ```bash
   eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
   cd ansible/k3s && uvx --from ansible-core ansible-playbook install-k3s.yaml
   ```

3. **Fetch kubeconfig** (replace `CONTROL_PLANE_IP`):
   ```bash
   CONTROL_PLANE_IP=192.168.69.10
   ssh debian@${CONTROL_PLANE_IP} 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/config
   sed -i "s/127.0.0.1/${CONTROL_PLANE_IP}/g" ~/.kube/config
   chmod 600 ~/.kube/config
   ```

4. **Bootstrap GitOps:**
   ```bash
   kubectl apply -k kubernetes/bootstrap/argocd
   ```
   Argo CD installs, then syncs `core/` and `apps/` via ApplicationSets.

## Kubernetes Structure

- `kubernetes/bootstrap/argocd/` — Argo CD install + root ApplicationSet resources
- `kubernetes/core/` — Cluster-wide platform services (cert-manager, CloudNativePG, MetalLB, monitoring, NFS provisioner, Sealed Secrets, Traefik)
- `kubernetes/apps/` — Application workloads (adguard, home-assistant, homepage, hortusfox, immich, jellyfin, linkding, mealie, paperless-ngx, planka, vaultwarden)

## Key Conventions

**Namespaces:** Argo CD auto-creates namespaces from directory names under `apps/` and `core/` via `CreateNamespace=true`. No `Namespace` manifest needed — just create the directory.

**App deployment patterns:**
- Most apps: raw Kustomize manifests (`deployment.yaml`, `service.yaml`, `ingress.yaml`, PVC)
- Some apps (Immich): Kustomize with embedded Helm charts (`helmCharts` in `kustomization.yaml`)
- A few (Jellyfin, monitoring): standalone Helm charts (`Chart.yaml` + `values.yaml`)

**Secrets:** Always use Bitnami Sealed Secrets. Plaintext `*secrets*.yaml` files are gitignored.
```bash
kubeseal --controller-namespace sealed-secrets --format yaml < secret.yaml > sealed-secret.yaml
```

**Database:** CloudNativePG is the standard Postgres operator. A shared cluster `postgres-shared` in namespace `databases` serves most apps. Immich has its own dedicated CNPG cluster at `kubernetes/apps/immich/postgres/`. Backups use Barman with S3 on the NAS.

**Storage:**
- Default: Local Path Provisioner (K3s built-in)
- NFS-backed dynamic StorageClass available via `kubernetes/core/nfs-provisioner/`

**Networking:** MetalLB for LoadBalancer services (IP pools in `kubernetes/core/metallb-config/`). Traefik handles ingress; cert-manager issues TLS via Let's Encrypt.

## Do's and Don'ts

- **DO** check `terraform/proxmox/inventory.ini` exists before running Ansible.
- **DO NOT** hardcode IP addresses — use Terraform variables or Ansible inventory.
- **DO NOT** commit `terraform.tfvars` or kubeconfig files.
