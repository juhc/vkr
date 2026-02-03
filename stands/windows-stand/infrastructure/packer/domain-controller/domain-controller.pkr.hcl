# Packer конфигурация для создания шаблона Domain Controller на Proxmox (UEFI/OVMF)
# Поддерживаемые версии: Windows Server 2016/2019/2022/2025 с ролью AD DS (зависит от вашего ISO)

packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.1"
    }
  }
}

# Переменные
# Общие переменные передаются через var-file:
# - ..\\variables.common.pkrvars.hcl
# - ..\\variables.secrets.pkrvars.hcl
# Здесь определены только специфичные для этой машины переменные

variable "proxmox_api_url" {
  type        = string
  description = "URL API Proxmox (из общих переменных)"
  default     = ""
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API Token ID (из общих переменных)"
  sensitive   = true
  default     = ""
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API Token Secret (из общих переменных)"
  sensitive   = true
  default     = ""
}

variable "proxmox_node" {
  type        = string
  description = "Имя узла Proxmox (из общих переменных)"
  default     = "pve"
}

variable "iso_storage_pool" {
  type        = string
  description = "Имя storage pool для ISO (из общих переменных)"
  default     = "local"
}

variable "iso_file" {
  type        = string
  description = "Имя ISO файла в Proxmox storage"
  default     = ""
}

variable "iso_url" {
  type        = string
  description = "URL для загрузки ISO"
  default     = ""
}

variable "iso_checksum" {
  type        = string
  description = "SHA256 checksum ISO файла"
  default     = ""
}

variable "vm_name" {
  type        = string
  description = "Имя виртуальной машины"
  default     = "domain-controller-template"
}

variable "vm_id" {
  type        = number
  description = "ID виртуальной машины"
  default     = 9002
}

variable "cpu_cores" {
  type        = number
  description = "Количество ядер CPU"
  default     = 4
}

variable "memory" {
  type        = number
  description = "Объем памяти в МБ"
  default     = 8192
}

variable "disk_size" {
  type        = string
  description = "Размер диска"
  default     = "100G"
}

variable "storage_pool" {
  type        = string
  description = "Имя storage pool для диска (из общих переменных)"
  default     = "local-lvm"
}

variable "efi_storage_pool" {
  type        = string
  description = "Storage pool для EFI диска (UEFI/OVMF)"
  default     = "local-lvm"
}

variable "proxmox_bridge" {
  type        = string
  description = "Bridge в Proxmox для сетевого адаптера"
  default     = "vmbr0"
}

variable "virtio_iso_file" {
  type        = string
  description = "VirtIO ISO в Proxmox storage (guest tools/qemu-ga), например local:iso/virtio-win-0.1.285.iso"
  default     = ""
}

variable "windows_edition" {
  type        = string
  description = "Редакция Windows Server"
  default     = "Windows Server 2019 Standard"
}

variable "admin_username" {
  type        = string
  description = "Имя администратора (из общих переменных)"
  default     = "Administrator"
}

variable "admin_password" {
  type        = string
  description = "Пароль администратора (из общих переменных)"
  sensitive   = true
  default     = "TempPassword123!"
}

variable "winrm_username" {
  type        = string
  description = "Имя пользователя для WinRM (из общих переменных)"
  default     = "Administrator"
}

variable "winrm_password" {
  type        = string
  description = "Пароль для WinRM (из общих переменных)"
  sensitive   = true
  default     = "TempPassword123!"
}

# SSH (для работы через OpenSSH; удобно для Ansible и надёжнее WinRM)
variable "ssh_username" {
  type        = string
  description = "Пользователь для SSH (обычно Administrator)"
  default     = "Administrator"
}

variable "ssh_password" {
  type        = string
  description = "Пароль для SSH"
  sensitive   = true
  default     = "TempPassword123!"
}

variable "domain_name" {
  type        = string
  description = "Имя домена Active Directory"
  default     = "training.local"
}

# Источник для Proxmox
source "proxmox-iso" "domain-controller" {
  proxmox_url              = var.proxmox_api_url
  username                  = var.proxmox_api_token_id
  token                     = var.proxmox_api_token_secret
  insecure_skip_tls_verify  = true
  
  node                 = var.proxmox_node
  vm_id                = var.vm_id
  vm_name              = var.vm_name

  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool  = var.efi_storage_pool
    pre_enrolled_keys = true
  }
  
  # Boot ISO (новый синтаксис)
  boot_iso {
    type             = "ide"
    index            = "2"
    iso_file         = var.iso_file != "" ? var.iso_file : null
    iso_url          = var.iso_url != "" ? var.iso_url : null
    iso_checksum     = var.iso_checksum != "" ? var.iso_checksum : null
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
  }

  # Дополнительный ISO (VirtIO) — опционально
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
  
  # Ресурсы VM
  cores                = var.cpu_cores
  memory               = var.memory
  cpu_type             = "host"
  
  # Диск
  disks {
    type              = "scsi"
    disk_size         = var.disk_size
    storage_pool      = var.storage_pool
  }
  
  # Сеть
  network_adapters {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }
  
  # Дополнительные настройки
  qemu_agent           = true
  scsi_controller      = "virtio-scsi-pci"
  
  # Proxmox ostype
  os = "win10"

  boot = "order=ide2;ide3;scsi0;net0"
  boot_wait = "8s"
  boot_command = [
    "<wait5><spacebar><wait1><spacebar><wait1><spacebar>"
  ]
  
  # Коммуникатор: SSH (OpenSSH ставится в ISO скриптом SetupComplete)
  communicator            = "ssh"
  ssh_username            = var.ssh_username
  ssh_password            = var.ssh_password
  ssh_port                = 22
  ssh_timeout             = "2h"
  ssh_handshake_attempts  = 200
}

# Сборка
build {
  name = "domain-controller"
  
  sources = ["source.proxmox-iso.domain-controller"]
  
  # Ожидание готовности WinRM
  provisioner "powershell" {
    inline = [
      "Write-Host 'Windows Server установлен и готов к использованию'",
      "Get-Date"
    ]
  }
  
  # Дополнительная настройка (опционально)
  provisioner "powershell" {
    scripts = [
      "scripts/configure-domain-controller.ps1"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Завершение работы...'",
      "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    ]
  }
}
