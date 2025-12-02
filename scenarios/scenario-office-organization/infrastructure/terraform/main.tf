# Terraform конфигурация для развертывания инфраструктуры офисной организации

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

# Локальные переменные
locals {
  base_image_path = var.base_image_path != "" ? var.base_image_path : "/var/lib/libvirt/images/ubuntu-20.04-server-cloudimg-amd64.img"
  ssh_public_key  = file(var.ssh_public_key_path)
}

# Переменные
variable "base_image_path" {
  description = "Путь к базовому образу Ubuntu"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Путь к SSH публичному ключу"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "disk_pool" {
  description = "Имя пула дисков libvirt"
  type        = string
  default     = "default"
}

# Создание сетей
module "network_dmz" {
  source = "../../terraform/modules/network"
  
  network_name = "dmz-network"
  network_cidr = "192.168.10.0/24"
  dhcp_enabled = true
  dhcp_start   = "192.168.10.100"
  dhcp_end     = "192.168.10.200"
}

module "network_internal" {
  source = "../../terraform/modules/network"
  
  network_name = "internal-network"
  network_cidr = "192.168.20.0/24"
  dhcp_enabled = true
  dhcp_start   = "192.168.20.100"
  dhcp_end     = "192.168.20.200"
}

module "network_development" {
  source = "../../terraform/modules/network"
  
  network_name = "development-network"
  network_cidr = "192.168.30.0/24"
  dhcp_enabled = true
  dhcp_start   = "192.168.30.100"
  dhcp_end     = "192.168.30.200"
}

module "network_management" {
  source = "../../terraform/modules/network"
  
  network_name = "management-network"
  network_cidr = "192.168.40.0/24"
  dhcp_enabled = true
  dhcp_start   = "192.168.40.100"
  dhcp_end     = "192.168.40.200"
}

# DMZ серверы
module "web_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "web-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 50
  disk_pool      = var.disk_pool
  network_name   = module.network_dmz.network_name
  ip_address     = "192.168.10.10"
  gateway        = "192.168.10.1"
  dns_servers    = ["192.168.10.30", "192.168.20.20", "8.8.8.8"]
  hostname       = "web-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "mail_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "mail-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 50
  disk_pool      = var.disk_pool
  network_name   = module.network_dmz.network_name
  ip_address     = "192.168.10.20"
  gateway        = "192.168.10.1"
  dns_servers    = ["192.168.10.30", "192.168.20.20", "8.8.8.8"]
  hostname       = "mail-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "dns_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "dns-server"
  cpu            = 2
  memory         = 2048
  disk_size      = 30
  disk_pool      = var.disk_pool
  network_name   = module.network_dmz.network_name
  ip_address     = "192.168.10.30"
  gateway        = "192.168.10.1"
  dns_servers    = ["192.168.10.30", "8.8.8.8"]
  hostname       = "dns-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

# Внутренние серверы
module "file_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "file-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 200
  disk_pool      = var.disk_pool
  network_name   = module.network_internal.network_name
  ip_address     = "192.168.20.10"
  gateway        = "192.168.20.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "file-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "db_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "db-server"
  cpu            = 4
  memory         = 8192
  disk_size      = 200
  disk_pool      = var.disk_pool
  network_name   = module.network_internal.network_name
  ip_address     = "192.168.20.30"
  gateway        = "192.168.20.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "db-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "backup_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "backup-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 500
  disk_pool      = var.disk_pool
  network_name   = module.network_internal.network_name
  ip_address     = "192.168.20.40"
  gateway        = "192.168.20.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "backup-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "monitoring_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "monitoring-server"
  cpu            = 4
  memory         = 8192
  disk_size      = 100
  disk_pool      = var.disk_pool
  network_name   = module.network_internal.network_name
  ip_address     = "192.168.20.50"
  gateway        = "192.168.20.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "monitoring-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

# Серверы разработки
module "dev_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "dev-server"
  cpu            = 4
  memory         = 8192
  disk_size      = 100
  disk_pool      = var.disk_pool
  network_name   = module.network_development.network_name
  ip_address     = "192.168.30.10"
  gateway        = "192.168.30.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "dev-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "test_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "test-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 100
  disk_pool      = var.disk_pool
  network_name   = module.network_development.network_name
  ip_address     = "192.168.30.20"
  gateway        = "192.168.30.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "test-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

module "cicd_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "ci-cd-server"
  cpu            = 4
  memory         = 8192
  disk_size      = 100
  disk_pool      = var.disk_pool
  network_name   = module.network_development.network_name
  ip_address     = "192.168.30.30"
  gateway        = "192.168.30.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "ci-cd-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

# Управляющие серверы
module "jump_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "jump-server"
  cpu            = 2
  memory         = 2048
  disk_size      = 30
  disk_pool      = var.disk_pool
  network_name   = module.network_management.network_name
  ip_address     = "192.168.40.10"
  gateway        = "192.168.40.1"
  dns_servers    = ["192.168.20.20", "192.168.10.30", "8.8.8.8"]
  hostname       = "jump-server"
  domain         = "techservice.local"
  base_image_path = local.base_image_path
  ssh_public_key = local.ssh_public_key
}

# Выводы для генерации Ansible инвентаря
output "web_server_ip" {
  value       = module.web_server.vm_ip_addresses[0]
  description = "IP адрес веб-сервера"
}

output "mail_server_ip" {
  value       = module.mail_server.vm_ip_addresses[0]
  description = "IP адрес почтового сервера"
}

output "dns_server_ip" {
  value       = module.dns_server.vm_ip_addresses[0]
  description = "IP адрес DNS сервера"
}

output "file_server_ip" {
  value       = module.file_server.vm_ip_addresses[0]
  description = "IP адрес файлового сервера"
}

output "db_server_ip" {
  value       = module.db_server.vm_ip_addresses[0]
  description = "IP адрес сервера базы данных"
}

output "backup_server_ip" {
  value       = module.backup_server.vm_ip_addresses[0]
  description = "IP адрес сервера резервного копирования"
}

output "monitoring_server_ip" {
  value       = module.monitoring_server.vm_ip_addresses[0]
  description = "IP адрес сервера мониторинга"
}

output "dev_server_ip" {
  value       = module.dev_server.vm_ip_addresses[0]
  description = "IP адрес сервера разработки"
}

output "test_server_ip" {
  value       = module.test_server.vm_ip_addresses[0]
  description = "IP адрес сервера тестирования"
}

output "cicd_server_ip" {
  value       = module.cicd_server.vm_ip_addresses[0]
  description = "IP адрес CI/CD сервера"
}

output "jump_server_ip" {
  value       = module.jump_server.vm_ip_addresses[0]
  description = "IP адрес jump-сервера"
}

output "all_servers" {
  value = {
    dmz = {
      web_server  = module.web_server.vm_ip_addresses[0]
      mail_server = module.mail_server.vm_ip_addresses[0]
      dns_server  = module.dns_server.vm_ip_addresses[0]
    }
    internal = {
      file_server      = module.file_server.vm_ip_addresses[0]
      db_server        = module.db_server.vm_ip_addresses[0]
      backup_server    = module.backup_server.vm_ip_addresses[0]
      monitoring_server = module.monitoring_server.vm_ip_addresses[0]
    }
    development = {
      dev_server  = module.dev_server.vm_ip_addresses[0]
      test_server = module.test_server.vm_ip_addresses[0]
      cicd_server = module.cicd_server.vm_ip_addresses[0]
    }
    management = {
      jump_server = module.jump_server.vm_ip_addresses[0]
    }
  }
  description = "Все IP адреса серверов"
}
