# Конфигурация Terraform для развертывания инфраструктуры ISP компании на Proxmox

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
  
  # Настройка бэкенда для хранения состояния (опционально)
  # backend "remote" {
  #   organization = "your-org"
  #   workspaces {
  #     name = "isp-company-proxmox"
  #   }
  # }
}

# Провайдер Proxmox
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = var.proxmox_tls_insecure
  
  # Опционально: таймауты
  pm_timeout = 300
}

# Переменные определены в variables.tf

# RADIUS сервер
module "radius_server" {
  count = var.enable_radius_server ? 1 : 0
  
  source = "../../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "radius-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.radius_cpu
  memory = var.radius_memory
  disk_size = var.radius_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.radius_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "radius-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : (var.ssh_public_key != "" ? var.ssh_public_key : "")
  ssh_user       = var.ssh_user
  
  vlan_tag = var.radius_vlan_tag
}

# Сервер сервисов (объединенный биллинг + веб)
module "services_server" {
  count = var.enable_services_server ? 1 : 0
  
  source = "../../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "services-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.services_cpu
  memory = var.services_memory
  disk_size = var.services_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.services_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "services-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : (var.ssh_public_key != "" ? var.ssh_public_key : "")
  ssh_user       = var.ssh_user
  
  vlan_tag = var.services_vlan_tag
}

# Сервер управления (объединенный мониторинг + jump)
module "management_server" {
  count = var.enable_management_server ? 1 : 0
  
  source = "../../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "management-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.management_cpu
  memory = var.management_memory
  disk_size = var.management_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.management_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "management-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : (var.ssh_public_key != "" ? var.ssh_public_key : "")
  ssh_user       = var.ssh_user
  
  vlan_tag = var.management_vlan_tag
}

# Уязвимый компьютер администратора
module "admin_workstation" {
  count = var.enable_admin_workstation ? 1 : 0
  
  source = "../../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "admin-workstation"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.admin_workstation_cpu
  memory = var.admin_workstation_memory
  disk_size = var.admin_workstation_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.admin_workstation_ip}/24"  # Теперь 192.168.30.20
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "admin-workstation"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : (var.ssh_public_key != "" ? var.ssh_public_key : "")
  ssh_user       = var.ssh_user
  
  vlan_tag = var.admin_workstation_vlan_tag
}

# Машина атакующего (Kali Linux)
module "kali_attacker" {
  count = var.enable_kali_attacker ? 1 : 0
  
  source = "../../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "kali-attacker"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_kali_template_name  # Отдельный шаблон для Kali
  
  cpu    = var.kali_cpu
  memory = var.kali_memory
  disk_size = var.kali_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.kali_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "kali-attacker"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key
  ssh_user       = "kali"  # Kali Linux использует пользователя 'kali'
  
  vlan_tag = var.kali_vlan_tag
}

# Outputs для использования в Ansible
output "vm_ips" {
  description = "IP адреса всех виртуальных машин"
  value = {
    radius_server    = var.enable_radius_server ? module.radius_server[0].vm_ips[0] : null
    services_server  = var.enable_services_server ? module.services_server[0].vm_ips[0] : null
    management_server = var.enable_management_server ? module.management_server[0].vm_ips[0] : null
    admin_workstation = var.enable_admin_workstation ? module.admin_workstation[0].vm_ips[0] : null
    kali_attacker     = var.enable_kali_attacker ? module.kali_attacker[0].vm_ips[0] : null
  }
}

output "vm_names" {
  description = "Имена всех виртуальных машин"
  value = {
    radius_server    = var.enable_radius_server ? module.radius_server[0].vm_names[0] : null
    services_server  = var.enable_services_server ? module.services_server[0].vm_names[0] : null
    management_server = var.enable_management_server ? module.management_server[0].vm_names[0] : null
    admin_workstation = var.enable_admin_workstation ? module.admin_workstation[0].vm_names[0] : null
    kali_attacker     = var.enable_kali_attacker ? module.kali_attacker[0].vm_names[0] : null
  }
}

