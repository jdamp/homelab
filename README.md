# Introduction

This repository contains code for my homelab,currently consisting of a single Lenovo M920q node (6C i5-8500T CPU, 16 GB RAM, 256 GB SSD).
Using proxmox, multiple VMs will be run on this node for a k3s cluster.


## Repository structure
- The `proxmox` folder contains the configuration for the proxmox VMs on the physical hosts
- The `k3s` folder contains Ansible playbooks which set up the installation of k3s on the VM nodes