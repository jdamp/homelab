# Setup steps


## Proxmox API token

Create a proxmox user and terraform according to the [docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs#creating-the-proxmox-user-and-role-for-terraform):

```bash
pveum role add TerraformRole -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.PowerMgmt SDN.Use"
pveum user add terraform-user@pve --password <password>
pveum aclmod / -user terraform-user@pve -role TerraformRole
```

Create an API token:

```bash
pveum user token add terraform-user@pve terraform-token
```
Make sure that priviledge separation is turned off for the API token.
This way, it will have the same permissions as the role associated to the user.

For some of the resources, e.g. handling cloud-init files, the terraform provider requires connection via
ssh-key. For this purpose, follow these steps on the proxmox node:
```bash
# Create a linux user
adduser --disabled-password --gecos "" terraform-user
mkdir -p /home/terraform-user/.ssh
chmod 700 /home/terraform-user/.ssh

echo "ssh-ed25519 AA..." | tee /home/terraform-user/.ssh/authorized_keys
chmod 600 /home/terraform-user/.ssh/authorized_keys
chown -R terraform-user:terraform-user /home/terraform-user/.ssh
```
and give the user write access to the snippets directory:

```bash
chown -R terraform-user:terraform-user /var/lib/vz/snippets
```

## Proxmox VM template