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

// Combine all nodes for cloud-init config
locals {
  all_nodes = concat(var.k3s_control_plane_nodes, var.k3s_worker_nodes)
  all_nodes_map = {
    for node in local.all_nodes : node.name => node
  }
}

// Cloud-init: per-VM user_data_config
resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  for_each = local.all_nodes_map
  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.proxmox_node

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.value.name}
    fqdn: ${each.value.name}
    manage_etc_hosts: true
    timezone: Europe/Berlin
    users:
      - default
      - name: ${var.ssh_user}
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
      - nfs-common
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "${each.value.name}-user-data.yaml"
  }
}


// K3s Control Plane Nodes
resource "proxmox_virtual_environment_vm" "k3s_control_plane" {
  for_each = {
    for node in var.k3s_control_plane_nodes : node.name => node
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
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config[each.value.name].id

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

// K3s Worker Nodes
resource "proxmox_virtual_environment_vm" "k3s_worker" {
  for_each = {
    for node in var.k3s_worker_nodes : node.name => node
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
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config[each.value.name].id

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


resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
      control_plane=proxmox_virtual_environment_vm.k3s_control_plane
      worker_nodes=proxmox_virtual_environment_vm.k3s_worker
      ssh_key_path=data.local_file.ssh_public_key.filename
   })

   filename = "${path.module}/inventory.ini"
   file_permission = "0644"
 }