
To get started, read the project documentation in the `README.md` file.

# Dev instructions

- Do not update README.md files or create documentation files, unless you are explicitly instructed to do so.
- Use comments to explain the general functionality of the code, avoid including inline comments which perform specific edits.

## Terraform instructions
Use the `bpg/proxmox` terraform provider to manage VM configuration.
Keep variables in `variables.tf` and sensitive data in `terraform.tfvars`.


## Ansible instructions
Ansible commands can be run using `uvx`, e.g.:
```bash
uvx --from ansible-core ansible-playbook playbook.yaml
```