// SSH Public Key Data Source
data "local_file" "ssh_public_key" {
  filename = pathexpand(var.ssh_public_key_path)
}

// Cloud Image Download
resource "proxmox_virtual_environment_download_file" "cloud_image" {
  for_each = toset(var.cloud_image_nodes)
  content_type = "import"
  datastore_id = "local"
  node_name    = each.value
  url          = var.cloud_image_url
  file_name    = var.cloud_image_filename
}

// Create mapping of cloud image IDs by node
locals {
  cloud_image_ids = {
    for node, resource in proxmox_virtual_environment_download_file.cloud_image : node => resource.id
  }
}


// K3s Cluster Nodes (Control Plane and Workers)
resource "proxmox_virtual_environment_vm" "k3s_nodes" {
  for_each = {
    for node in var.k3s_nodes : node.name => node
  }
  name        = "${each.value.name}"
  description = each.value.description
  node_name   = each.value.proxmox_node
  stop_on_destroy = true

  # CPU Configuration
  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  # Memory Configuration
  memory {
    dedicated = each.value.memory_mb
  }

  # Enable QEMU agent
  agent {
    enabled = true
  }

  # Disk Configuration
  disk {
    datastore_id = "local-lvm"
    import_from  = local.cloud_image_ids[each.value.proxmox_node]
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = each.value.disk_size_gb
  }

  # Network Configuration
  network_device {
    bridge = var.network_bridge
  }

  # Cloud-Init Configuration
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = var.gateway
      }
    }

    user_account {
      username = var.ssh_user
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
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
