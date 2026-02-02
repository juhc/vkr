# Terraform конфигурация для Windows Server
# Версии: Windows Server 2016, 2019, 2022

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

# Windows Server
resource "proxmox_vm_qemu" "windows_server" {
  name        = var.windows_server_name
  description = "Windows Server для обучения защите ОС"
  target_node = var.proxmox_node
  
  # Клонирование из шаблона или создание из ISO
  clone = var.template_name != "" ? var.template_name : null
  
  # Ресурсы
  cores   = var.windows_server_cores
  sockets = 1
  memory  = var.windows_server_memory
  
  # Диск
  disk {
    type    = "scsi"
    storage = var.storage
    size    = var.windows_server_disk_size
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
    vm_name = proxmox_vm_qemu.windows_server.name
    vm_ip   = var.windows_server_ip
    user    = var.admin_user
    pwd     = sha256(var.admin_password)
    key     = sha256(var.admin_ssh_public_key)
  }

  depends_on = [proxmox_vm_qemu.windows_server]

  connection {
    type     = "ssh"
    host     = var.windows_server_ip
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
output "windows_server_ip" {
  value       = var.windows_server_ip
  description = "IP адрес Windows Server (настраивается вручную или через cloud-init)"
}

output "windows_server_name" {
  value       = proxmox_vm_qemu.windows_server.name
  description = "Имя Windows Server"
}
