# Terraform конфигурация для учебной инфраструктуры по защите ОС
# Инфраструктура включает: Windows Server 2016, Windows 10 Pro, Ubuntu Server
# Используется Proxmox VE для виртуализации

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

# Переменные определены в variables.tf

# Провайдер Proxmox
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_debug            = false
}

# Ubuntu Server - демонстрация уязвимостей Linux ОС
resource "proxmox_vm_qemu" "ubuntu_server" {
  name        = "ubuntu-server-training"
  desc        = "Ubuntu Server 20.04 для обучения защите ОС Linux"
  target_node = var.proxmox_node
  
  # Клонирование из шаблона
  clone = var.template_name
  
  # Ресурсы
  cores   = 2
  sockets = 1
  memory  = 4096
  
  # Диск
  disk {
    type    = "scsi"
    storage = var.storage
    size    = "50G"
    format  = "raw"
  }
  
  # Сеть
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  # Cloud-init для начальной настройки
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key != "" ? var.ssh_public_key : try(file("${path.home}/.ssh/id_ed25519.pub"), try(file("${path.home}/.ssh/id_rsa.pub"), ""))
  ipconfig0 = "ip=192.168.100.10/24,gw=192.168.100.1"
  nameserver = "8.8.8.8"
  
  # Дополнительные настройки
  agent    = 1
  qemu_os  = "l26"
  onboot   = true
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Windows Server 2016 - демонстрация уязвимостей Windows ОС
# Примечание: Windows машины создаются вручную через веб-интерфейс Proxmox
# Terraform может только управлять уже созданными VM или использовать ISO установку

# Windows 10 Pro - демонстрация уязвимостей рабочих станций Windows
# Аналогично Windows Server 2016

# Выводы
output "ubuntu_server_ip" {
  value       = proxmox_vm_qemu.ubuntu_server.default_ipv4_address
  description = "IP адрес Ubuntu Server"
}

output "ubuntu_server_name" {
  value       = proxmox_vm_qemu.ubuntu_server.name
  description = "Имя Ubuntu Server"
}

output "windows_server_2016_ip" {
  value       = "192.168.100.20"
  description = "IP адрес Windows Server 2016 (настраивается вручную в Proxmox)"
}

output "windows_10_pro_ip" {
  value       = "192.168.100.30"
  description = "IP адрес Windows 10 Pro (настраивается вручную в Proxmox)"
}

output "all_machines" {
  value = {
    ubuntu_server      = proxmox_vm_qemu.ubuntu_server.default_ipv4_address
    windows_server_2016 = "192.168.100.20"
    windows_10_pro     = "192.168.100.30"
  }
  description = "Все IP адреса машин"
}

