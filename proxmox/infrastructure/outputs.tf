# Control Plane Outputs
output "control_plane_nodes" {
  description = "Control plane node information"
  value = {
    for idx, vm in proxmox_virtual_environment_vm.k3s_control : vm.name => {
      id     = vm.vm_id
      ip     = var.control_plane_nodes[idx].ip_address
      cores  = vm.cpu[0].cores
      memory = vm.memory[0].dedicated
      ssh    = "ssh ${var.ssh_user}@${var.control_plane_nodes[idx].ip_address}"
    }
  }
}

# Worker Node Outputs
output "worker_nodes" {
  description = "Worker node information"
  value = {
    for idx, vm in proxmox_virtual_environment_vm.k3s_worker : vm.name => {
      id     = vm.vm_id
      ip     = var.worker_nodes[idx].ip_address
      cores  = vm.cpu[0].cores
      memory = vm.memory[0].dedicated
      ssh    = "ssh ${var.ssh_user}@${var.worker_nodes[idx].ip_address}"
    }
  }
}

# Summary
output "cluster_summary" {
  description = "K3s cluster summary"
  value = {
    cluster_name       = var.cluster_name
    control_plane_ips  = [for node in var.control_plane_nodes : node.ip_address]
    worker_ips         = [for node in var.worker_nodes : node.ip_address]
    total_nodes        = length(var.control_plane_nodes) + length(var.worker_nodes)
    total_cores        = sum([for node in var.control_plane_nodes : node.cpu_cores]) + sum([for node in var.worker_nodes : node.cpu_cores])
    total_memory_mb    = sum([for node in var.control_plane_nodes : node.memory_mb]) + sum([for node in var.worker_nodes : node.memory_mb])
    total_disk_size_gb = sum([for node in var.control_plane_nodes : node.disk_size_gb]) + sum([for node in var.worker_nodes : node.disk_size_gb])
  }
}
