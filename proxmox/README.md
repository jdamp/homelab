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

## Proxmox VM template