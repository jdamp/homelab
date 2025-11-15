#!/bin/bash
set -e

# Script to create a Proxmox VM template for Debian cloud images
# Usage: ./create-template.sh <PROXMOX_HOST> [IMAGE_URL] [VMID] [SSH_KEY_PATH]

PROXMOX_HOST=${1:?Error: PROXMOX_HOST is required as the first argument}
IMAGE_URL=${2:-"https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"}
VMID=${3:-9000}
SSH_KEY_PATH=${4:-"$HOME/.ssh/id_rsa.pub"}

SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")

IMAGE_NAME=$(basename "$IMAGE_URL")
TEMPLATE_NAME=$(basename "$IMAGE_NAME" .qcow2)-template

echo "Creating VM template with the following configuration:"
echo "  Proxmox Host: $PROXMOX_HOST"
echo "  Image URL: $IMAGE_URL"
echo "  VM ID: $VMID"
echo "  SSH Key: $SSH_KEY_PATH_EXPANDED"
echo "  Template Name: $TEMPLATE_NAME"
echo ""

# Execute all commands on the Proxmox host
ssh root@"$PROXMOX_HOST" bash -s <<EOF
set -e

echo "Downloading cloud image..."
wget "$IMAGE_URL" -O /tmp/"$IMAGE_NAME"

echo "Creating VM..."
qm create $VMID --name "$TEMPLATE_NAME" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

echo "Importing disk..."
qm importdisk $VMID /tmp/"$IMAGE_NAME" local-lvm

echo "Attaching disk to VM..."
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VMID-disk-0

echo "Configuring cloud-init drive..."
qm set $VMID --ide2 local-lvm:cloudinit

echo "Setting boot order..."
qm set $VMID --boot c --bootdisk scsi0

echo "Adding serial console..."
qm set $VMID --serial0 socket --vga serial0

echo "Configuring cloud-init settings..."
qm set $VMID --ipconfig0 ip=dhcp

echo "Enabling QEMU Guest Agent..."
qm set $VMID --agent enabled=1

echo "Converting VM to template..."
qm template $VMID

echo "Cleaning up..."
rm -f /tmp/"$IMAGE_NAME"

echo "Template creation complete!"
echo "Template ID: $VMID"
echo "Template Name: $TEMPLATE_NAME"
EOF

echo "VM template successfully created on $PROXMOX_HOST"