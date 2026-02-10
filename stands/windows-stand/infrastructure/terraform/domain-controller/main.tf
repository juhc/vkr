# Terraform конфигурация для Domain Controller
# Версии: Windows Server 2016, 2019, 2022 с ролью AD DS

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

# Domain Controller
resource "proxmox_vm_qemu" "domain_controller" {
  name        = var.dc_name
  description = "Domain Controller для обучения защите Active Directory"
  target_node = var.proxmox_node
  pool        = var.proxmox_pool != "" ? var.proxmox_pool : null
  
  # Клонирование из шаблона или создание из ISO
  clone = var.template_name != "" ? var.template_name : null
  
  # Ресурсы
  cores   = var.dc_cores
  sockets = 1
  memory  = var.dc_memory
  
  # Диск
  disk {
    type    = "scsi"
    storage = var.storage
    size    = var.dc_disk_size
    format  = "raw"
  }
  
  # Сеть
  network {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }
  
  # Настройки для Windows Server
  agent    = 1
  qemu_os  = "win10"
  onboot   = true
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Опционально: задать пароль/ключ админ-пользователя сразу после клона (нужен SSH доступ в шаблоне)
resource "null_resource" "admin_access" {
  count = var.admin_password != "" || var.admin_ssh_public_key != "" ? 1 : 0

  triggers = {
    vm_name = proxmox_vm_qemu.domain_controller.name
    vm_ip   = var.dc_ip
    user    = var.admin_user
    pwd     = sha256(var.admin_password)
    key     = sha256(var.admin_ssh_public_key)
  }

  depends_on = [proxmox_vm_qemu.domain_controller]

  connection {
    type     = "ssh"
    host     = var.dc_ip
    user     = var.admin_user
    password = var.bootstrap_admin_password != "" ? var.bootstrap_admin_password : null
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "if ('${var.admin_password}' -ne '') { net user ${var.admin_user} \"${var.admin_password}\" }",
      "if ('${var.admin_ssh_public_key}' -ne '') { " +
        "New-Item -Force -ItemType Directory -Path $env:USERPROFILE\\.ssh | Out-Null; " +
        "Set-Content -Force -Path $env:USERPROFILE\\.ssh\\authorized_keys -Value \"${var.admin_ssh_public_key}\"; " +
        "icacls $env:USERPROFILE\\.ssh\\authorized_keys /inheritance:r /grant \"$env:USERNAME:(R,W)\" | Out-Null " +
      "}",
    ]
  }
}

# Выводы
output "dc_ip" {
  value       = var.dc_ip
  description = "IP адрес Domain Controller (настраивается вручную или через cloud-init)"
}

output "dc_name" {
  value       = proxmox_vm_qemu.domain_controller.name
  description = "Имя Domain Controller"
}

output "domain_name" {
  value       = var.domain_name
  description = "Имя домена Active Directory"
}
