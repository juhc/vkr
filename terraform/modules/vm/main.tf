# Terraform модуль для создания виртуальных машин

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
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
  type        = number
  default     = 50
}

variable "disk_pool" {
  description = "Имя пула дисков libvirt"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Имя сети libvirt"
  type        = string
}

variable "ip_address" {
  description = "IP адрес виртуальной машины (если пустой, используется DHCP)"
  type        = string
  default     = ""
}

variable "netmask" {
  description = "Маска подсети"
  type        = string
  default     = "255.255.255.0"
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
  default     = "techservice.local"
}

variable "base_image_path" {
  description = "Путь к базовому образу"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH публичный ключ для доступа"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Cloud-init user data"
  type        = string
  default     = ""
}

# Получение информации о сети
data "libvirt_network" "network" {
  name = var.network_name
}

# Создание облачного диска из базового образа
resource "libvirt_volume" "base" {
  count  = var.vm_count
  name   = "${var.vm_name}-${count.index + 1}-base.qcow2"
  pool   = var.disk_pool
  source = var.base_image_path
  format = "qcow2"
}

# Создание диска для виртуальной машины
resource "libvirt_volume" "vm_disk" {
  count          = var.vm_count
  name           = "${var.vm_name}-${count.index + 1}.qcow2"
  base_volume_id = libvirt_volume.base[count.index].id
  pool           = var.disk_pool
  size           = var.disk_size * 1024 * 1024 * 1024 # Конвертация GB в байты
}

# Создание cloud-init диска
resource "libvirt_cloudinit_disk" "cloudinit" {
  count     = var.vm_count
  name      = "${var.vm_name}-${count.index + 1}-cloudinit.iso"
  pool      = var.disk_pool
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    hostname     = var.hostname != "" ? "${var.hostname}-${count.index + 1}" : "${var.vm_name}-${count.index + 1}"
    fqdn         = var.hostname != "" ? "${var.hostname}-${count.index + 1}" : "${var.vm_name}-${count.index + 1}"
    domain       = var.domain
    ip_address   = var.ip_address != "" ? var.ip_address : ""
    netmask      = var.netmask
    gateway      = var.gateway != "" ? var.gateway : ""
    dns_servers  = var.dns_servers
    ssh_key      = var.ssh_public_key != "" ? var.ssh_public_key : "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... lab-key"
    use_static_ip = var.ip_address != ""
  })
}

# Создание виртуальной машины
resource "libvirt_domain" "vm" {
  count  = var.vm_count
  name   = "${var.vm_name}-${count.index + 1}"
  memory = var.memory
  vcpu   = var.cpu

  cloudinit = libvirt_cloudinit_disk.cloudinit[count.index].id

  disk {
    volume_id = libvirt_volume.vm_disk[count.index].id
  }

  network_interface {
    network_id   = data.libvirt_network.network.id
    hostname     = var.hostname != "" ? "${var.hostname}-${count.index + 1}" : "${var.vm_name}-${count.index + 1}"
    addresses    = var.ip_address != "" ? [var.ip_address] : []
    wait_for_lease = var.ip_address == "" ? true : false
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Выводы модуля
output "vm_ids" {
  description = "ID виртуальных машин"
  value       = libvirt_domain.vm[*].id
}

output "vm_names" {
  description = "Имена виртуальных машин"
  value       = libvirt_domain.vm[*].name
}

output "vm_ip_addresses" {
  description = "IP адреса виртуальных машин"
  value       = libvirt_domain.vm[*].network_interface[0].addresses
}

output "vm_macs" {
  description = "MAC адреса виртуальных машин"
  value       = libvirt_domain.vm[*].network_interface[0].mac
}

