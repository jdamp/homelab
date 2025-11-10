// K3s Control Plane Node
resource "proxmox_vm_qemu" "k3s_control" {
  name        = "${var.cluster_name}-control-01"
  desc        = "K3s Control Plane Node"
  target_node = var.proxmox_node
  

  # Clone from template
  clone   = var.template_name
  os_type = "cloud-init"
  

  cores   = 2    
  memory  = 4096


  # Enable QEMU agent
  agent = 1
  
  # Boot settings
  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-pci"
  
  # Disk
  disk {
    slot    = 0
    size    = "40G"
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
  ipconfig0 = "ip=${var.control_plane_ip}/24,gw=${var.gateway}"
  
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
