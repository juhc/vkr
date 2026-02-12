# Terraform конфигурация для Linux сервера
# Поддерживаемые дистрибутивы: Ubuntu Server, Debian Server, CentOS, AlmaLinux

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

# Провайдер Proxmox
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_debug            = false
}

locals {
  server_mgmt_enabled = trimspace(var.proxmox_mgmt_bridge) != ""
  server_mgmt_ipconfig = !local.server_mgmt_enabled ? null : (
    var.mgmt_use_dhcp ? "ip=dhcp" : (
      var.mgmt_gateway != ""
      ? "ip=${var.linux_server_mgmt_ip}/${var.mgmt_cidr_prefix},gw=${var.mgmt_gateway}"
      : "ip=${var.linux_server_mgmt_ip}/${var.mgmt_cidr_prefix}"
    )
  )
}

# Linux сервер
resource "proxmox_vm_qemu" "linux_server" {
  name        = var.linux_server_name
  description = "Linux сервер для обучения защите ОС"
  target_node = var.proxmox_node
  pool        = var.proxmox_pool != "" ? var.proxmox_pool : null
  
  # Клонирование из шаблона
  clone = var.template_name
  full_clone = true
  
  # SCSI controller / boot (template создан под virtio-scsi + scsi0)
  scsihw   = "virtio-scsi-pci"
  bios     = "ovmf"
  machine  = "q35"
  bootdisk = "scsi0"
  boot     = "order=scsi0;net0"

  # Консоль/дисплей:
  # - vga=serial0 часто ломает noVNC (консоль "отваливается"/постоянно переподключается)
  # - фиксируем стандартный VGA, чтобы консоль Proxmox открывалась стабильно
  vga {
    type = "std"
  }

  # Оставляем serial0 как дополнительный канал для отладки (xterm.js), не мешает noVNC
  serial {
    id   = 0
    type = "socket"
  }
  
  # Ресурсы
  cores   = var.linux_server_cores
  sockets = 1
  memory  = var.linux_server_memory
  
  # Диски/сеть нужно описать явно для telmate/proxmox v3, иначе провайдер может “обнулить” диски после клона.
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.storage
    size    = var.linux_server_disk_size
  }
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage
  }
  
  network {
    id     = 0
    model  = "virtio"
    bridge = var.proxmox_bridge
  }
  dynamic "network" {
    for_each = local.server_mgmt_enabled ? [1] : []
    content {
      id     = 1
      model  = "virtio"
      bridge = var.proxmox_mgmt_bridge
    }
  }
  
  # Cloud-init для начальной настройки
  ciuser     = var.linux_server_user
  cipassword = var.linux_server_password != "" ? var.linux_server_password : null
  sshkeys    = var.ssh_public_key != "" ? var.ssh_public_key : try(file(pathexpand("~/.ssh/id_ed25519.pub")), try(file(pathexpand("~/.ssh/id_rsa.pub")), ""))
  ipconfig0  = var.use_dhcp ? "ip=dhcp" : "ip=${var.linux_server_ip}/${var.cidr_prefix},gw=${var.gateway}"
  ipconfig1  = local.server_mgmt_ipconfig
  nameserver = var.nameserver
  
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

# Выводы
output "linux_server_ip" {
  value       = proxmox_vm_qemu.linux_server.default_ipv4_address != "" ? proxmox_vm_qemu.linux_server.default_ipv4_address : var.linux_server_ip
  description = "IP адрес Linux сервера"
}

output "linux_server_name" {
  value       = proxmox_vm_qemu.linux_server.name
  description = "Имя Linux сервера"
}

output "linux_server_ssh_ip" {
  value       = local.server_mgmt_enabled ? (var.mgmt_use_dhcp ? proxmox_vm_qemu.linux_server.default_ipv4_address : var.linux_server_mgmt_ip) : (proxmox_vm_qemu.linux_server.default_ipv4_address != "" ? proxmox_vm_qemu.linux_server.default_ipv4_address : var.linux_server_ip)
  description = "IP для SSH/Ansible (второй интерфейс при наличии, иначе основной)"
}
