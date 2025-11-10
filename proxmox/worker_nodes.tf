// K3s Worker Nodes
resource "proxmox_vm_qemu" "k3s_worker" {
  count       = 2
  name        = "${var.cluster_name}-worker-${format("%02d", count.index + 1)}"
  target_node = var.proxmox_node
  desc        = "K3s Worker Node ${count.index + 1}"

  # Clone from template
  clone   = var.template_name
  os_type = "cloud-init"
  
  # VM Settings
  cores   = 2
  sockets = 1
  cpu     = "host"
  memory  = 5120
  
  # Enable QEMU agent
  agent = 1
  
  # Boot settings
  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-pci"
  
  # Disk
  disk {
    slot    = 0
    size    = "60G"
    type    = "scsi"
    storage = var.template_storage
    iothread = 1
    discard = "on"
    ssd     = 1
  }
  
  # Network
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  # Cloud-Init Settings
  ipconfig0 = "ip=${count.index == 0 ? var.worker1_ip : var.worker2_ip}/24,gw=${var.gateway}"
  
  nameserver = var.nameserver
  
  ciuser  = var.ssh_user
  sshkeys = var.ssh_public_key
  
  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}
