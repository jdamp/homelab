# K3s Nodes Outputs
output "k3s_nodes" {
  description = "K3s node information"
  value = {
    for name, vm in proxmox_virtual_environment_vm.k3s_nodes : vm.name => {
      id          = vm.vm_id
      description = vm.description
      ip          = vm.initialization[0].ip_config[0].ipv4[0].address
      cores       = vm.cpu[0].cores
      memory      = vm.memory[0].dedicated
      ssh         = "ssh ${var.ssh_user}@${split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]}"
    }
  }
}

# Summary
output "cluster_summary" {
  description = "K3s cluster summary"
  value = {
    cluster_name       = var.cluster_name
    node_ips           = [for node in var.k3s_nodes : node.ip_address]
    total_nodes        = length(var.k3s_nodes)
    total_cores        = sum([for node in var.k3s_nodes : node.cpu_cores])
    total_memory_mb    = sum([for node in var.k3s_nodes : node.memory_mb])
    total_disk_size_gb = sum([for node in var.k3s_nodes : node.disk_size_gb])
  }
}
