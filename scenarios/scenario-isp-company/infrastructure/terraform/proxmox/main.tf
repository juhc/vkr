# Конфигурация Terraform для развертывания инфраструктуры ISP компании на Proxmox

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
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
  source = "../../../../terraform/modules/proxmox-vm"
  
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
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : var.ssh_public_key
  ssh_user       = var.ssh_user
  
  vlan_tag = var.radius_vlan_tag
}

# Биллинговый сервер
module "billing_server" {
  source = "../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "billing-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.billing_cpu
  memory = var.billing_memory
  disk_size = var.billing_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.billing_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "billing-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : var.ssh_public_key
  ssh_user       = var.ssh_user
  
  vlan_tag = var.billing_vlan_tag
}

# Веб-сервер
module "web_server" {
  source = "../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "web-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.web_cpu
  memory = var.web_memory
  disk_size = var.web_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.web_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "web-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : var.ssh_public_key
  ssh_user       = var.ssh_user
  
  vlan_tag = var.web_vlan_tag
}

# Сервер мониторинга
module "monitoring_server" {
  source = "../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "monitoring-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.monitoring_cpu
  memory = var.monitoring_memory
  disk_size = var.monitoring_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.monitoring_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "monitoring-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : var.ssh_public_key
  ssh_user       = var.ssh_user
  
  vlan_tag = var.monitoring_vlan_tag
}

# Jump-сервер
module "jump_server" {
  source = "../../../../terraform/modules/proxmox-vm"
  
  vm_name      = "jump-server"
  target_node = var.proxmox_target_node
  template_name = var.proxmox_template_name
  
  cpu    = var.jump_cpu
  memory = var.jump_memory
  disk_size = var.jump_disk_size
  disk_storage = var.proxmox_disk_storage
  
  network_bridge = var.network_bridge
  ip_address     = "${var.jump_ip}/24"
  gateway        = var.network_gateway
  dns_servers    = var.dns_servers
  
  hostname = "jump-server"
  domain   = var.domain
  
  ssh_public_key = var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) : var.ssh_public_key
  ssh_user       = var.ssh_user
  
  vlan_tag = var.jump_vlan_tag
}

# Машина атакующего (Kali Linux)
module "kali_attacker" {
  source = "../../../../terraform/modules/proxmox-vm"
  
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
    radius_server    = module.radius_server.vm_ips[0]
    billing_server   = module.billing_server.vm_ips[0]
    web_server       = module.web_server.vm_ips[0]
    monitoring_server = module.monitoring_server.vm_ips[0]
    jump_server       = module.jump_server.vm_ips[0]
    kali_attacker     = module.kali_attacker.vm_ips[0]
  }
}

output "vm_names" {
  description = "Имена всех виртуальных машин"
  value = {
    radius_server    = module.radius_server.vm_names[0]
    billing_server   = module.billing_server.vm_names[0]
    web_server       = module.web_server.vm_names[0]
    monitoring_server = module.monitoring_server.vm_names[0]
    jump_server       = module.jump_server.vm_names[0]
    kali_attacker     = module.kali_attacker.vm_names[0]
  }
}

