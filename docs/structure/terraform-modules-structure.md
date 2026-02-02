# Структура Terraform модулей для проекта киберучений

## Обзор модулей

Terraform модули организованы по функциональному принципу для обеспечения переиспользования и модульности.

## Структура модуля VM (terraform/modules/vm/)

```
vm/
├── main.tf                    # Основные ресурсы виртуальных машин
├── variables.tf               # Входные переменные модуля
├── outputs.tf                 # Выходные значения модуля
├── versions.tf                # Версии провайдеров
├── README.md                  # Документация модуля
└── examples/                  # Примеры использования
    ├── basic-vm/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── terraform.tfvars
    ├── multi-vm/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── terraform.tfvars
    └── windows-vm/
        ├── main.tf
        ├── variables.tf
        └── terraform.tfvars
```

### Содержимое файлов модуля VM

#### main.tf
```hcl
# Создание виртуальной машины
resource "vsphere_virtual_machine" "vm" {
  count            = var.vm_count
  name             = "${var.vm_name_prefix}-${count.index + 1}"
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder

  num_cpus               = var.num_cpus
  memory                 = var.memory
  guest_id               = var.guest_id
  scsi_type              = var.scsi_type
  scsi_bus_sharing       = var.scsi_bus_sharing
  scsi_controller_count   = var.scsi_controller_count

  network_interface {
    network_id   = var.network_id
    adapter_type = var.adapter_type
  }

  disk {
    label            = "disk0"
    size             = var.disk_size
    eagerly_scrub    = var.eagerly_scrub
    thin_provisioned = var.thin_provisioned
  }

  clone {
    template_uuid = var.template_uuid
    customize {
      linux_options {
        host_name = "${var.vm_name_prefix}-${count.index + 1}"
        domain    = var.domain
      }
      network_interface {
        ipv4_address = var.static_ip ? var.ipv4_addresses[count.index] : null
        ipv4_netmask = var.static_ip ? var.ipv4_netmask : null
      }
      ipv4_gateway    = var.static_ip ? var.ipv4_gateway : null
      dns_server_list = var.dns_servers
    }
  }

  tags = var.tags
}
```

#### variables.tf
```hcl
variable "vm_count" {
  description = "Количество виртуальных машин для создания"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "Префикс имени виртуальной машины"
  type        = string
}

variable "resource_pool_id" {
  description = "ID пула ресурсов vSphere"
  type        = string
}

variable "datastore_id" {
  description = "ID хранилища данных vSphere"
  type        = string
}

variable "folder" {
  description = "Папка для размещения ВМ"
  type        = string
  default     = ""
}

variable "num_cpus" {
  description = "Количество CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Объем памяти в MB"
  type        = number
  default     = 4096
}

variable "guest_id" {
  description = "ID гостевой ОС"
  type        = string
  default     = "ubuntu64Guest"
}

variable "network_id" {
  description = "ID сети"
  type        = string
}

variable "disk_size" {
  description = "Размер диска в GB"
  type        = number
  default     = 50
}

variable "template_uuid" {
  description = "UUID шаблона ВМ"
  type        = string
}

variable "static_ip" {
  description = "Использовать статические IP адреса"
  type        = bool
  default     = false
}

variable "ipv4_addresses" {
  description = "Список IPv4 адресов"
  type        = list(string)
  default     = []
}

variable "ipv4_netmask" {
  description = "Маска подсети IPv4"
  type        = number
  default     = 24
}

variable "ipv4_gateway" {
  description = "Шлюз IPv4"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Список DNS серверов"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "domain" {
  description = "Домен для ВМ"
  type        = string
  default     = "lab.local"
}

variable "tags" {
  description = "Теги для ВМ"
  type        = map(string)
  default     = {}
}
```

#### outputs.tf
```hcl
output "vm_ids" {
  description = "ID созданных виртуальных машин"
  value       = vsphere_virtual_machine.vm[*].id
}

output "vm_names" {
  description = "Имена созданных виртуальных машин"
  value       = vsphere_virtual_machine.vm[*].name
}

output "vm_ip_addresses" {
  description = "IP адреса виртуальных машин"
  value       = vsphere_virtual_machine.vm[*].default_ip_address
}

output "vm_guest_ip_addresses" {
  description = "Гостевые IP адреса виртуальных машин"
  value       = vsphere_virtual_machine.vm[*].guest_ip_addresses
}

output "vm_macs" {
  description = "MAC адреса сетевых интерфейсов"
  value       = vsphere_virtual_machine.vm[*].network_interface[0].mac_address
}
```

## Структура модуля Network (terraform/modules/network/)

```
network/
├── main.tf                    # Создание сетей и подсетей
├── variables.tf                # Переменные модуля
├── outputs.tf                  # Выходные значения
├── versions.tf                 # Версии провайдеров
├── README.md                   # Документация
└── examples/
    ├── isolated-network/
    ├── dmz-network/
    └── multi-tier-network/
```

### Содержимое файлов модуля Network

#### main.tf
```hcl
# Создание виртуальной сети
resource "vsphere_virtual_network" "network" {
  name          = var.network_name
  datacenter_id = var.datacenter_id
  type          = var.network_type
  vlan_id       = var.vlan_id
}

# Создание порт-группы
resource "vsphere_distributed_port_group" "port_group" {
  count                         = var.create_port_group ? 1 : 0
  name                          = var.port_group_name
  distributed_virtual_switch_uuid = var.dvs_uuid
  vlan_id                       = var.vlan_id
  active_uplinks                = var.active_uplinks
  standby_uplinks               = var.standby_uplinks

  dynamic "vlan_range" {
    for_each = var.vlan_ranges
    content {
      min_vlan = vlan_range.value.min_vlan
      max_vlan = vlan_range.value.max_vlan
    }
  }
}

# Настройка брандмауэра (если используется NSX)
resource "nsxt_policy_segment" "segment" {
  count        = var.create_nsx_segment ? 1 : 0
  display_name = var.segment_name
  description  = var.segment_description
  
  connectivity_path = var.connectivity_path
  transport_zone_path = var.transport_zone_path
  
  subnet {
    cidr = var.subnet_cidr
    dhcp_ranges = var.dhcp_ranges
  }
  
  tag {
    scope = "environment"
    tag   = var.environment_tag
  }
}
```

## Структура модуля Security (terraform/modules/security/)

```
security/
├── main.tf                    # Ресурсы безопасности
├── variables.tf               # Переменные
├── outputs.tf                 # Выходные значения
├── versions.tf                # Версии провайдеров
├── firewall.tf                # Правила брандмауэра
├── ssl.tf                     # SSL сертификаты
├── encryption.tf              # Шифрование
└── README.md                  # Документация
```

### Содержимое файлов модуля Security

#### firewall.tf
```hcl
# Правила брандмауэра для NSX
resource "nsxt_policy_security_policy" "firewall_rules" {
  count        = var.create_firewall_rules ? 1 : 0
  display_name = var.firewall_policy_name
  description  = var.firewall_policy_description
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = false

  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      display_name    = rule.value.name
      description     = rule.value.description
      action          = rule.value.action
      logged          = rule.value.logged
      direction       = rule.value.direction
      ip_version      = rule.value.ip_version
      
      source_groups   = rule.value.source_groups
      destination_groups = rule.value.destination_groups
      services        = rule.value.services
      
      tag {
        scope = "environment"
        tag   = var.environment_tag
      }
    }
  }
}
```

## Структура модуля Monitoring (terraform/modules/monitoring/)

```
monitoring/
├── main.tf                    # Основные ресурсы мониторинга
├── variables.tf               # Переменные
├── outputs.tf                 # Выходные значения
├── versions.tf                # Версии провайдеров
├── prometheus.tf              # Prometheus конфигурация
├── grafana.tf                 # Grafana конфигурация
├── alertmanager.tf            # Alertmanager конфигурация
└── README.md                  # Документация
```

## Использование модулей в сценариях

### Пример использования в сценарии

```hcl
# terraform/stands/scenario-1/main.tf
module "network" {
  source = "../../modules/network"
  
  network_name    = "scenario-1-network"
  datacenter_id   = var.datacenter_id
  network_type    = "distributed"
  vlan_id         = 100
  create_port_group = true
  port_group_name = "scenario-1-pg"
}

module "web_server" {
  source = "../../modules/vm"
  
  vm_count           = 1
  vm_name_prefix     = "web-server"
  resource_pool_id   = var.resource_pool_id
  datastore_id       = var.datastore_id
  network_id         = module.network.network_id
  template_uuid      = var.ubuntu_template_uuid
  num_cpus          = 2
  memory            = 4096
  disk_size         = 50
  static_ip         = true
  ipv4_addresses    = ["192.168.100.10"]
  ipv4_netmask      = 24
  ipv4_gateway      = "192.168.100.1"
  
  tags = {
    scenario = "scenario-1"
    role     = "web-server"
    environment = "lab"
  }
}

module "database_server" {
  source = "../../modules/vm"
  
  vm_count           = 1
  vm_name_prefix     = "db-server"
  resource_pool_id   = var.resource_pool_id
  datastore_id       = var.datastore_id
  network_id         = module.network.network_id
  template_uuid      = var.ubuntu_template_uuid
  num_cpus          = 2
  memory            = 8192
  disk_size         = 100
  static_ip         = true
  ipv4_addresses    = ["192.168.100.20"]
  ipv4_netmask      = 24
  ipv4_gateway      = "192.168.100.1"
  
  tags = {
    scenario = "scenario-1"
    role     = "database"
    environment = "lab"
  }
}

module "security" {
  source = "../../modules/security"
  
  create_firewall_rules = true
  firewall_policy_name = "scenario-1-firewall"
  environment_tag      = "lab"
  
  firewall_rules = [
    {
      name        = "allow-http"
      description = "Allow HTTP traffic"
      action      = "ALLOW"
      logged      = true
      direction   = "IN_OUT"
      ip_version  = "IPV4"
      source_groups      = ["ANY"]
      destination_groups = [module.web_server.vm_ids[0]]
      services    = ["HTTP"]
    },
    {
      name        = "allow-https"
      description = "Allow HTTPS traffic"
      action      = "ALLOW"
      logged      = true
      direction   = "IN_OUT"
      ip_version  = "IPV4"
      source_groups      = ["ANY"]
      destination_groups = [module.web_server.vm_ids[0]]
      services    = ["HTTPS"]
    },
    {
      name        = "allow-db-access"
      description = "Allow database access from web server"
      action      = "ALLOW"
      logged      = true
      direction   = "IN_OUT"
      ip_version  = "IPV4"
      source_groups      = [module.web_server.vm_ids[0]]
      destination_groups = [module.database_server.vm_ids[0]]
      services    = ["MySQL"]
    }
  ]
}
```

## Переменные окружения

### terraform.tfvars для сценария
```hcl
# Основные настройки
datacenter_id        = "datacenter-123"
resource_pool_id     = "resgroup-456"
datastore_id         = "datastore-789"

# Шаблоны ОС
ubuntu_template_uuid = "vm-template-ubuntu-20.04"
centos_template_uuid = "vm-template-centos-8"
windows_template_uuid = "vm-template-windows-2019"

# Настройки сети
dns_servers = ["8.8.8.8", "8.8.4.4"]
domain      = "lab.local"

# Теги
common_tags = {
  project     = "cyber-range-lab"
  environment = "lab"
  managed_by  = "terraform"
}
```

## Версионирование модулей

### versions.tf
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
  }
}
```

## Лучшие практики

1. **Модульность**: Каждый модуль должен выполнять одну конкретную задачу
2. **Переиспользование**: Модули должны быть универсальными и настраиваемыми
3. **Документация**: Каждый модуль должен иметь README с примерами
4. **Тестирование**: Модули должны быть покрыты тестами
5. **Версионирование**: Использовать семантическое версионирование для модулей
6. **Безопасность**: Не хранить секреты в коде, использовать переменные
7. **Идемпотентность**: Модули должны быть идемпотентными
8. **Обратная совместимость**: Изменения должны быть обратно совместимыми

Эта структура обеспечивает гибкость и переиспользование Terraform модулей в проекте киберучений.
