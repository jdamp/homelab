# K3s Cluster Setup

Ansible playbook to install and configure the k3s cluster.
Requires the Proxmox Terraform configuration to be applied first to generate the inventory file.
Ensure that the ssh-agent is configured with the ssh-key for the nodes:
``` bash
eval `ssh-agent`
ssh-add ~/.ssh/id_ed25519
```
Run ansible using uv:

```bash
uvx --from ansible-core ansible-playbook playbook.yaml
```


Receive the kubeconfig file for the cluster from the control node and update the IP address accordingly.
```bash
ssh debian@192.168.0.10 sudo chmod 644 /etc/rancher/k3s/k3s.yaml
scp debian@192.168.0.10:/etc/rancher/k3s/k3s.yaml ~/.kube/config
ssh debian@192.168.0.10 sudo chmod 600 /etc/rancher/k3s/k3s.yaml
sed -i 's/127.0.0.1/192.168.0.10/g' ~/.kube/config
```
