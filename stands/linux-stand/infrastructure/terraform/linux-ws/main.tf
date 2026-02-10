# Terraform конфигурация для рабочей станции Linux (Desktop)
# Поддерживаемые дистрибутивы: Ubuntu Desktop, Debian Desktop

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

# Рабочая станция Linux (Desktop)
resource "proxmox_vm_qemu" "linux_ws" {
  name        = var.linux_ws_name
  description = "Рабочая станция Linux Desktop для обучения защите ОС"
  target_node = var.proxmox_node
  pool        = var.proxmox_pool != "" ? var.proxmox_pool : null
  
  # Клонирование из шаблона
  clone = var.template_name
  full_clone = true
  
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
  cores   = var.linux_ws_cores
  sockets = 1
  memory  = var.linux_ws_memory
  
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.storage
    size    = var.linux_ws_disk_size
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
  
  # Cloud-init для начальной настройки
  ciuser     = var.linux_ws_user
  cipassword = var.linux_ws_password != "" ? var.linux_ws_password : null
  sshkeys    = var.ssh_public_key != "" ? var.ssh_public_key : try(file(pathexpand("~/.ssh/id_ed25519.pub")), try(file(pathexpand("~/.ssh/id_rsa.pub")), ""))
  ipconfig0  = var.use_dhcp ? "ip=dhcp" : "ip=${var.linux_ws_ip}/${var.cidr_prefix},gw=${var.gateway}"
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
output "linux_ws_ip" {
  value       = proxmox_vm_qemu.linux_ws.default_ipv4_address != "" ? proxmox_vm_qemu.linux_ws.default_ipv4_address : var.linux_ws_ip
  description = "IP адрес рабочей станции Linux"
}

output "linux_ws_name" {
  value       = proxmox_vm_qemu.linux_ws.name
  description = "Имя рабочей станции Linux"
}
