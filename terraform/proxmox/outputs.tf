# K3s Control Plane Nodes Outputs
output "k3s_control_plane_nodes" {
  description = "K3s control plane node information"
  value = {
    for name, vm in proxmox_virtual_environment_vm.k3s_control_plane : vm.name => {
      id          = vm.vm_id
      description = vm.description
      ip          = vm.initialization[0].ip_config[0].ipv4[0].address
      cores       = vm.cpu[0].cores
      memory      = vm.memory[0].dedicated
      ssh         = "ssh ${var.ssh_user}@${split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]}"
    }
  }
}

# K3s Worker Nodes Outputs
output "k3s_worker_nodes" {
  description = "K3s worker node information"
  value = {
    for name, vm in proxmox_virtual_environment_vm.k3s_worker : vm.name => {
      id          = vm.vm_id
      description = vm.description
      ip          = vm.initialization[0].ip_config[0].ipv4[0].address
      cores       = vm.cpu[0].cores
      memory      = vm.memory[0].dedicated
      ssh         = "ssh ${var.ssh_user}@${split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]}"
    }
  }
}