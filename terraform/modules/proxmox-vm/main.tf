# Terraform модуль для создания виртуальных машин в Proxmox

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
}

# Переменные модуля
variable "vm_name" {
  description = "Имя виртуальной машины"
  type        = string
}

variable "vm_count" {
  description = "Количество виртуальных машин"
  type        = number
  default     = 1
}

variable "target_node" {
  description = "Имя узла Proxmox, на котором будет создана ВМ"
  type        = string
}

variable "template_name" {
  description = "Имя шаблона для клонирования"
  type        = string
}

variable "cpu" {
  description = "Количество CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Объем памяти в MB"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Размер диска в GB"
  type        = string
  default     = "50G"
}

variable "disk_storage" {
  description = "Имя хранилища для диска"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Имя сетевого моста"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "IP адрес виртуальной машины (CIDR формат, например: 192.168.10.10/24)"
  type        = string
  default     = ""
}

variable "gateway" {
  description = "Шлюз по умолчанию"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Список DNS серверов"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "hostname" {
  description = "Имя хоста"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Домен"
  type        = string
  default     = "internetplus.local"
}

variable "ssh_public_key" {
  description = "SSH публичный ключ для доступа"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "Пользователь для SSH доступа"
  type        = string
  default     = "ubuntu"
}

variable "vlan_tag" {
  description = "VLAN тег (опционально)"
  type        = number
  default     = null
}

variable "onboot" {
  description = "Запускать ВМ при загрузке Proxmox"
  type        = bool
  default     = true
}

variable "agent" {
  description = "Включить QEMU Guest Agent"
  type        = bool
  default     = true
}

variable "nameserver" {
  description = "DNS сервер (для cloud-init)"
  type        = string
  default     = ""
}

# Создание виртуальной машины
resource "proxmox_vm_qemu" "vm" {
  count       = var.vm_count
  name        = var.vm_count > 1 ? "${var.vm_name}-${count.index + 1}" : var.vm_name
  target_node = var.target_node
  clone       = var.template_name
  
  # Ресурсы
  cpu {
    cores  = var.cpu
    sockets = 1
    type   = "kvm64"  # Используем kvm64 для лучшей совместимости
  }
  memory  = var.memory
  kvm     = false  # Отключаем KVM, используем эмуляцию
  
  # Диск с virtio-scsi контроллером
  scsihw = "virtio-scsi-single"  # Используем virtio-scsi вместо обычного SCSI
  
  disk {
    slot    = "scsi0"
    storage = var.disk_storage
    size    = var.disk_size
    type    = "disk"
  }
  
  # Сеть
  network {
    id     = 0
    bridge = var.network_bridge
    model  = "virtio"
    tag    = var.vlan_tag
  }
  
  # Cloud-init настройки
  ciuser     = var.ssh_user
  cipassword = ""  # Пароль через cloud-init или SSH ключ
  
  # IP конфигурация
  ipconfig0 = var.ip_address != "" ? "ip=${var.ip_address},gw=${var.gateway != "" ? var.gateway : ""}" : ""
  
  # DNS
  nameserver = var.nameserver != "" ? var.nameserver : join(",", var.dns_servers)
  
  # SSH ключ
  sshkeys = var.ssh_public_key != "" ? var.ssh_public_key : ""
  
  # Дополнительные настройки
  onboot = var.onboot
  agent  = var.agent ? 1 : 0
  
  # VGA/VNC настройки для консоли
  vga {
    type = "std"  # Стандартный VGA, поддерживает VNC
    memory = 16   # Память для VGA (MB)
  }
  
  # Исправление Kernel panic: IO-APIC + timer doesn't work
  # Используем BIOS вместо UEFI и отключаем некоторые функции
  bios = "seabios"
  
  # Cloud-init опции
  cicustom = ""
  
  # Дополнительные параметры cloud-init
  # Используем user_data через cicustom или через отдельный cloud-init диск
  # Для простоты используем встроенные параметры Proxmox
  
  # Запуск после создания
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Выводы модуля
output "vm_ids" {
  description = "ID виртуальных машин"
  value       = proxmox_vm_qemu.vm[*].id
}

output "vm_names" {
  description = "Имена виртуальных машин"
  value       = proxmox_vm_qemu.vm[*].name
}

output "vm_ips" {
  description = "IP адреса виртуальных машин"
  value       = var.ip_address != "" ? [for i in range(var.vm_count) : var.ip_address] : []
}

output "vm_hostnames" {
  description = "Имена хостов виртуальных машин"
  value       = proxmox_vm_qemu.vm[*].name
}

