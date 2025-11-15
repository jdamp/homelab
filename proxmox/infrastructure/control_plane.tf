// K3s Control Plane Nodes
resource "proxmox_virtual_environment_vm" "k3s_control" {
  count       = length(var.control_plane_nodes)
  name        = "${var.cluster_name}-${var.control_plane_nodes[count.index].name}"
  description = "K3s Control Plane Node ${count.index + 1}"
  node_name   = var.control_plane_nodes[count.index].proxmox_node

  # Clone from template
  clone {
    vm_id = var.template_vm_id
  }

  # CPU Configuration
  cpu {
    cores = var.control_plane_nodes[count.index].cpu_cores
    type  = "host"
  }

  # Memory Configuration
  memory {
    dedicated = var.control_plane_nodes[count.index].memory_mb
  }

  # Enable QEMU agent
  agent {
    enabled = true
  }

  # Disk Configuration
  disk {
    datastore_id = var.template_storage # whether to use local-lvm, local
    interface    = "scsi"
    size         = var.control_plane_nodes[count.index].disk_size_gb
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
        address = "${var.control_plane_nodes[count.index].ip_address}/24"
        gateway = var.gateway
      }
    }

    # Note: can configure DNS servers with a DNS block once required

    user_account {
      username = var.ssh_user
      keys     = [var.ssh_public_key]
    }
  }

}
