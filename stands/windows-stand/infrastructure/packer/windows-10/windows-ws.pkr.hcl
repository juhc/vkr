                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          # Packer конфигурация для создания шаблона рабочей станции Windows
# Поддерживаемые ОС: Windows XP, Windows 7, Windows 10, Windows 11

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

variable "proxmox_bridge" {
  type        = string
  description = "Bridge в Proxmox для сетевого адаптера (из общих переменных)"
  default     = "vmbr0"
}

variable "iso_storage_pool" {
  type        = string
  description = "Имя storage pool для ISO (из общих переменных)"
  default     = "local"
}

variable "iso_file" {
  type        = string
  description = "Имя ISO файла в Proxmox storage (например: iso:windows-10.iso)"
  default     = ""
}

variable "iso_url" {
  type        = string
  description = "URL для загрузки ISO (если не используется iso_file)"
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
  default     = "windows-10-template"
}

variable "vm_id" {
  type        = number
  description = "ID виртуальной машины (должен быть уникальным)"
  default     = 9000
}

variable "cpu_cores" {
  type        = number
  description = "Количество ядер CPU"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Объем памяти в МБ"
  default     = 4096
}

variable "disk_size" {
  type        = string
  description = "Размер диска"
  default     = "50G"
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

variable "virtio_iso_file" {
  type        = string
  description = "VirtIO ISO в Proxmox storage (для qemu-ga и guest tools), например local:iso/virtio-win-0.1.262.iso"
  default     = ""
}

variable "windows_edition" {
  type        = string
  description = "Редакция Windows (например: Windows 10 Pro, Windows 11 Pro)"
  default     = "Windows 10 Pro"
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

# Источник для Proxmox
source "proxmox-iso" "windows-ws" {
  proxmox_url              = var.proxmox_api_url
  # Используем token для аутентификации
  # proxmox-iso поддерживает token через username и token параметры
  username                  = var.proxmox_api_token_id
  token                     = var.proxmox_api_token_secret
  insecure_skip_tls_verify  = true
  
  # Таймауты для операций Proxmox
  # Увеличиваем таймаут для стабильности соединения
  task_timeout = "30m"  # Таймаут для задач Proxmox (30 минут)
  
  node                 = var.proxmox_node
  vm_id                = var.vm_id
  vm_name              = var.vm_name

  # BIOS / UEFI (как в статье)
  # Для UEFI Windows обычно нужно использовать GPT-разметку в вашем autounattend.xml
  bios    = "ovmf"
  machine = "q35"

  efi_config {
    efi_storage_pool  = var.efi_storage_pool
    pre_enrolled_keys = true
  }
  
  # Boot ISO (новый синтаксис; старые поля iso_file/iso_storage_pool/unmount_iso deprecated)
  # ВАЖНО: используем уже подготовленный ISO, в который вы добавили:
  # - autounattend.xml (в корень ISO)
  # - $WinpeDriver$ (драйверы в корень ISO)
  boot_iso {
    # Зафиксируем слот CD-ROM, чтобы boot order "ide2" всегда попадал в установочный ISO
    # (после миграции на boot_iso плагин может выбирать другой слот автоматически).
    type            = "ide"
    index           = "2"
    iso_file         = var.iso_file != "" ? var.iso_file : null
    iso_url          = var.iso_url != "" ? var.iso_url : null
    iso_checksum     = var.iso_checksum != "" ? var.iso_checksum : null
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
  }

  # Дополнительный ISO (VirtIO) для установки qemu guest agent и virtio guest tools.
  # Если вы не загрузили virtio ISO в Proxmox, оставьте virtio_iso_file пустым и пропустите установку guest tools.
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
  
  # Диск (как в статье: virtio-scsi)
  disks {
    type              = "scsi"
    disk_size         = var.disk_size
    storage_pool      = var.storage_pool
  }

  scsi_controller = "virtio-scsi-pci"
  
  # Сеть (как в статье: virtio)
  network_adapters {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }
  
  # Дополнительные настройки
  qemu_agent           = true
  
  # Windows настройки
  os                   = "win10"

  # Boot order (важно для OVMF):
  # Ставим CD-ROM (ide2) первым, иначе UEFI может уйти в PXE до загрузки установщика.
  boot = "order=ide2;ide3;scsi0;net0"
  
  # Boot команда для загрузки с ISO (для Windows)
  # Windows автоматически найдет autounattend.xml в корне основного ISO
  # В UEFI часто появляется "Press any key to boot from CD or DVD..." — если не нажать,
  # прошивка быстро уходит на следующий boot option (PXE). Поэтому даём паузу и жмём пробел несколько раз.
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
  name = "windows-ws"
  
  sources = ["source.proxmox-iso.windows-ws"]
  
  # Ожидание готовности WinRM
  provisioner "powershell" {
    inline = [
      "Write-Host 'Windows установлен и готов к использованию'",
      "Get-Date"
    ]
  }
  
  # Дополнительная настройка (опционально)
  # Раскомментируйте, если создадите скрипт scripts/configure-windows.ps1
  # provisioner "powershell" {
  #   scripts = [
  #     "scripts/configure-windows.ps1"
  #   ]
  # }
  
  # Выключение VM после завершения сборки
  # Packer автоматически выключит VM после завершения всех provisioners
  provisioner "powershell" {
    inline = [
      "Write-Host 'Завершение работы...'",
      "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    ]
  }
}
