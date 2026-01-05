# K3s Cluster Setup

This folder contains Ansible playbooks to install and uninstall the K3s cluster.

## Prerequisites

- Apply the Proxmox Terraform config first so it generates `terraform/proxmox/inventory.ini`.
- Ensure `ssh-agent` is loaded with the SSH key used for the nodes.

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## Install

Run from this directory (uses `ansible.cfg` for inventory):

```bash
cd ansible/k3s
uvx --from ansible-core ansible-playbook install-k3s.yaml
```

Alternatively, from the repo root:

```bash
uvx --from ansible-core ansible-playbook -i terraform/proxmox/inventory.ini ansible/k3s/install-k3s.yaml
```

## Uninstall

```bash
cd ansible/k3s
uvx --from ansible-core ansible-playbook uninstall-k3s.yaml
```

## Fetch kubeconfig

Replace `CONTROL_PLANE_IP` with the first control-plane node IP.

```bash
CONTROL_PLANE_IP=192.168.178.10
mkdir -p ~/.kube
ssh debian@${CONTROL_PLANE_IP} 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/config
sed -i "s/127.0.0.1/${CONTROL_PLANE_IP}/g" ~/.kube/config
chmod 600 ~/.kube/config
```

## Notes

- Playbooks are implemented as roles in `roles/k3s` and `roles/k3s_uninstall`.
- `host_key_checking` is disabled in `ansible.cfg` for convenience.
