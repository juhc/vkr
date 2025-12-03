# Переменные для конфигурации Proxmox

# Настройки Proxmox API
variable "proxmox_api_url" {
  description = "URL API Proxmox (например: https://proxmox.example.com:8006/api2/json)"
  type        = string
}

# Флаги включения/отключения машин (для тестирования с ограниченными ресурсами)
variable "enable_radius_server" {
  description = "Создать RADIUS сервер"
  type        = bool
  default     = true
}

variable "enable_services_server" {
  description = "Создать сервер сервисов (объединенный биллинг + веб)"
  type        = bool
  default     = true
}

variable "enable_management_server" {
  description = "Создать сервер управления (объединенный мониторинг + jump)"
  type        = bool
  default     = true
}

variable "enable_kali_attacker" {
  description = "Создать машину атакующего (Kali Linux)"
  type        = bool
  default     = true
}

variable "enable_admin_workstation" {
  description = "Создать уязвимый компьютер администратора"
  type        = bool
  default     = true
}

variable "proxmox_api_token_id" {
  description = "ID токена API Proxmox (формат: user@realm!token-name)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Секрет токена API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Игнорировать ошибки TLS сертификата (только для разработки!)"
  type        = bool
  default     = false
}

variable "proxmox_target_node" {
  description = "Имя узла Proxmox, на котором будут созданы ВМ"
  type        = string
}

variable "proxmox_template_name" {
  description = "Имя шаблона Ubuntu для клонирования"
  type        = string
  default     = "ubuntu-20.04-template"
}

variable "proxmox_kali_template_name" {
  description = "Имя шаблона Kali Linux для клонирования"
  type        = string
  default     = "kali-linux-template"
}

variable "proxmox_disk_storage" {
  description = "Имя хранилища для дисков ВМ"
  type        = string
  default     = "local-lvm"
}

# Сетевые настройки
variable "network_bridge" {
  description = "Имя сетевого моста в Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Шлюз по умолчанию"
  type        = string
  default     = "192.168.10.1"
}

variable "dns_servers" {
  description = "Список DNS серверов"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "domain" {
  description = "Домен для машин"
  type        = string
  default     = "internetplus.local"
}

# SSH настройки
variable "ssh_public_key" {
  description = "SSH публичный ключ для доступа к ВМ (можно указать путь к файлу или сам ключ)"
  type        = string
  default     = ""
}

variable "ssh_public_key_file" {
  description = "Путь к файлу с SSH публичным ключом (альтернатива ssh_public_key)"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "Пользователь для SSH доступа"
  type        = string
  default     = "ubuntu"
}

# IP адреса машин
variable "radius_ip" {
  description = "IP адрес RADIUS сервера"
  type        = string
  default     = "192.168.10.10"
}

variable "services_ip" {
  description = "IP адрес сервера сервисов (объединенный биллинг + веб)"
  type        = string
  default     = "192.168.20.10"
}

variable "management_ip" {
  description = "IP адрес сервера управления (объединенный мониторинг + jump)"
  type        = string
  default     = "192.168.30.10"
}

variable "kali_ip" {
  description = "IP адрес машины атакующего (Kali)"
  type        = string
  default     = "192.168.50.10"
}

# Ресурсы для RADIUS сервера
variable "radius_cpu" {
  description = "Количество CPU для RADIUS сервера"
  type        = number
  default     = 2
}

variable "radius_memory" {
  description = "Память для RADIUS сервера (MB)"
  type        = number
  default     = 4096
}

variable "radius_disk_size" {
  description = "Размер диска для RADIUS сервера"
  type        = string
  default     = "50G"
}

variable "radius_vlan_tag" {
  description = "VLAN тег для RADIUS сервера"
  type        = number
  default     = null
}

# Ресурсы для сервера сервисов (объединенный биллинг + веб)
variable "services_cpu" {
  description = "Количество CPU для сервера сервисов"
  type        = number
  default     = 4
}

variable "services_memory" {
  description = "Память для сервера сервисов (MB)"
  type        = number
  default     = 8192
}

variable "services_disk_size" {
  description = "Размер диска для сервера сервисов"
  type        = string
  default     = "150G"
}

variable "services_vlan_tag" {
  description = "VLAN тег для сервера сервисов"
  type        = number
  default     = null
}

# Ресурсы для сервера управления (объединенный мониторинг + jump)
variable "management_cpu" {
  description = "Количество CPU для сервера управления"
  type        = number
  default     = 4
}

variable "management_memory" {
  description = "Память для сервера управления (MB)"
  type        = number
  default     = 6144
}

variable "management_disk_size" {
  description = "Размер диска для сервера управления"
  type        = string
  default     = "130G"
}

variable "management_vlan_tag" {
  description = "VLAN тег для сервера управления"
  type        = number
  default     = null
}

# IP адрес компьютера администратора (перемещен на освободившийся IP)
variable "admin_workstation_ip" {
  description = "IP адрес компьютера администратора"
  type        = string
  default     = "192.168.30.20"
}

# Ресурсы для компьютера администратора
variable "admin_workstation_cpu" {
  description = "Количество CPU для компьютера администратора"
  type        = number
  default     = 2
}

variable "admin_workstation_memory" {
  description = "Память для компьютера администратора (MB)"
  type        = number
  default     = 4096
}

variable "admin_workstation_disk_size" {
  description = "Размер диска для компьютера администратора"
  type        = string
  default     = "50G"
}

variable "admin_workstation_vlan_tag" {
  description = "VLAN тег для компьютера администратора"
  type        = number
  default     = null
}

# Ресурсы для Kali Linux
variable "kali_cpu" {
  description = "Количество CPU для Kali Linux"
  type        = number
  default     = 4
}

variable "kali_memory" {
  description = "Память для Kali Linux (MB)"
  type        = number
  default     = 8192
}

variable "kali_disk_size" {
  description = "Размер диска для Kali Linux"
  type        = string
  default     = "100G"
}

variable "kali_vlan_tag" {
  description = "VLAN тег для Kali Linux"
  type        = number
  default     = null
}

