# Setup Steps

This document outlines the required setup steps to configure Proxmox for Terraform management.

## Proxmox User and Role Setup

First create a dedicated Proxmox user and role for Terraform according to the [official provider documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs#creating-the-proxmox-user-and-role-for-terraform).

### 1. Create the Terraform Role

```bash
pveum role add TerraformRole -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.PowerMgmt SDN.Use"
```

### 2. Create the Terraform User

```bash
pveum user add terraform-user@pve --password <password>
pveum aclmod / -user terraform-user@pve -role TerraformRole
```

### 3. Create an API Token

```bash
pveum user token add terraform-user@pve terraform-token
```

**Important:** Disable privilege separation for the API token so it inherits the permissions from the TerraformRole.

## SSH Key Configuration

The Terraform provider requires SSH access for managing cloud-init files and other resources. Follow these steps on the Proxmox node:

### 1. Create a System User for SSH

```bash
adduser --disabled-password --gecos "" terraform-user
mkdir -p /home/terraform-user/.ssh
chmod 700 /home/terraform-user/.ssh
```

### 2. Add Your Public SSH Key

```bash
echo ssh-ed25519 AAAA... | tee /home/terraform-user/.ssh/authorized_keys
chmod 600 /home/terraform-user/.ssh/authorized_keys
chown -R terraform-user:terraform-user /home/terraform-user/.ssh
```

Replace the placeholder `ssh-ed25519 AAAA...` with my actual public SSH key.

### 3. Grant Snippet Directory Permissions

The newly created user needs access to the `/var/lib/vz/snippets` directory-.
```bash
groupadd terraform-group
usermod -aG terraform-group terraform-user

# Note: since destroy deletes the snippets directory, we require permissions one level higher
chgrp -R terraform-group /var/lib/vz/
chmod -R g+w /var/lib/vz/
```

This allows Terraform to upload and manage cloud-init configuration files.
