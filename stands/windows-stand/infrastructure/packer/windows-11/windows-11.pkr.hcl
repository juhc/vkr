# Packer конфигурация для создания шаблона Windows 11 на Proxmox (UEFI/OVMF)
#
# ВАЖНО: iso_file должен указывать на УЖЕ ПОДГОТОВЛЕННЫЙ ISO (как в статье):
# - в корне ISO лежит autounattend.xml
# - в корне ISO лежит папка $WinpeDriver$ с VirtIO драйверами (диск+сеть)
# - в ISO добавлены scripts: sources/$OEM$/$$/Setup/Scripts/SetupComplete.cmd + setup.ps1

packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.1"
    }
  }
}

variable "proxmox_api_url" {
  type    = string
  default = ""
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_bridge" {
  type    = string
  default = "vmbr0"
}

variable "iso_storage_pool" {
  type    = string
  default = "local"
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "efi_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "iso_file" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type    = string
  default = ""
}

variable "virtio_iso_file" {
  type        = string
  description = "VirtIO ISO в Proxmox storage (guest tools/qemu-ga), например local:iso/virtio-win-0.1.285.iso"
  default     = ""
}

variable "vm_name" {
  type    = string
  default = "windows-11-template"
}

variable "vm_id" {
  type    = number
  default = 9100
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type    = string
  default = "60G"
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type      = string
  sensitive = true
  default   = "TempPassword123!"
}

variable "ssh_username" {
  type    = string
  default = "Administrator"
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "TempPassword123!"
}

source "proxmox-iso" "windows-11" {
  proxmox_url             = var.proxmox_api_url
  username               = var.proxmox_api_token_id
  token                  = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  task_timeout = "30m"

  node    = var.proxmox_node
  vm_id   = var.vm_id
  vm_name = var.vm_name

  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool  = var.efi_storage_pool
    pre_enrolled_keys = true
  }

  boot_iso {
    type            = "ide"
    index           = "2"
    iso_file         = var.iso_file != "" ? var.iso_file : null
    iso_url          = var.iso_url != "" ? var.iso_url : null
    iso_checksum     = var.iso_checksum != "" ? var.iso_checksum : null
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
  }

  dynamic "additional_iso_files" {
    for_each = var.virtio_iso_file != "" ? [var.virtio_iso_file] : []
    content {
      type             = "ide"
      index            = "3"
      iso_file         = additional_iso_files.value
      iso_storage_pool = var.iso_storage_pool
      unmount          = true
    }
  }

  cores    = var.cpu_cores
  memory   = var.memory
  cpu_type = "host"

  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = var.storage_pool
  }

  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  qemu_agent = true

  # Proxmox ostype
  os = "win11"

  boot = "order=ide2;ide3;scsi0;net0"
  boot_wait = "8s"
  boot_command = [
    "<wait5><spacebar><wait1><spacebar><wait1><spacebar>"
  ]

  communicator            = "ssh"
  ssh_username            = var.ssh_username
  ssh_password            = var.ssh_password
  ssh_port                = 22
  ssh_timeout             = "2h"
  ssh_handshake_attempts  = 200
}

build {
  name    = "windows-11"
  sources = ["source.proxmox-iso.windows-11"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Windows 11 установлен и готов к использованию'",
      "Get-Date"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Завершение работы...'",
      "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    ]
  }
}

