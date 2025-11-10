# Control Plane Outputs
output "control_plane_node" {
  description = "Control plane node information"
  value = {
    name   = proxmox_vm_qemu.k3s_control.name
    id     = proxmox_vm_qemu.k3s_control.vmid
    ip     = var.control_plane_ip
    cores  = proxmox_vm_qemu.k3s_control.cores
    memory = proxmox_vm_qemu.k3s_control.memory
    ssh    = "ssh ${var.ssh_user}@${var.control_plane_ip}"
  }
}

# Worker Node Outputs
output "worker_nodes" {
  description = "Worker node information"
  value = {
    for idx, vm in proxmox_vm_qemu.k3s_worker : vm.name => {
      id     = vm.vmid
      ip     = idx == 0 ? var.worker1_ip : var.worker2_ip
      cores  = vm.cores
      memory = vm.memory
      ssh    = "ssh ${var.ssh_user}@${idx == 0 ? var.worker1_ip : var.worker2_ip}"
    }
  }
}

# Summary
output "cluster_summary" {
  description = "K3s cluster summary"
  value = {
    cluster_name    = var.cluster_name
    control_plane_ip = var.control_plane_ip
    worker_ips      = [var.worker1_ip, var.worker2_ip]
    total_nodes     = 3
    total_cores     = 6
    total_memory_gb = 14
  }
}
