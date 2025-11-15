// K3s Worker Nodes
resource "proxmox_virtual_environment_vm" "k3s_worker" {
  count       = length(var.worker_nodes)
  name        = "${var.cluster_name}-${var.worker_nodes[count.index].name}"
  description = "K3s Worker Node ${count.index + 1}"
  node_name   = var.worker_nodes[count.index].proxmox_node

  # Clone from template
  clone {
    vm_id = var.template_vm_id
  }

  # CPU Configuration
  cpu {
    cores = var.worker_nodes[count.index].cpu_cores
    type  = "host"
  }

  # Memory Configuration
  memory {
    dedicated = var.worker_nodes[count.index].memory_mb
  }

  # Enable QEMU agent
  agent {
    enabled = true
  }

  # Disk Configuration
  disk {
    datastore_id = var.template_storage
    interface    = "scsi0"
    size         = var.worker_nodes[count.index].disk_size_gb
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  # Network Configuration
  network_device {
    bridge = var.network_bridge
    model  = var.network_model
  }

  # Cloud-Init Configuration
  initialization {
    ip_config {
      ipv4 {
        address = "${var.worker_nodes[count.index].ip_address}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      username = var.ssh_user
      keys     = [var.ssh_public_key]
    }
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network_device,
      disk,
    ]
  }
}
