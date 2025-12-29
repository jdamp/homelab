[control_plane]
%{ for vm in control_plane }
${vm.name} ansible_host=${split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]} ansible_user=debian
%{ endfor ~}

[worker_nodes]
%{ for vm in worker_nodes }
${vm.name} ansible_host=${split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]} ansible_user=debian
%{ endfor ~}

[all:vars]
ansible_ssh_private_key_file=${ssh_key_path}