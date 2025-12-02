# Переменные для конфигурации Proxmox

# Настройки Proxmox API
variable "proxmox_api_url" {
  description = "URL API Proxmox (например: https://proxmox.example.com:8006/api2/json)"
  type        = string
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
  description = "SSH публичный ключ для доступа к ВМ"
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

variable "billing_ip" {
  description = "IP адрес биллингового сервера"
  type        = string
  default     = "192.168.20.10"
}

variable "web_ip" {
  description = "IP адрес веб-сервера"
  type        = string
  default     = "192.168.20.20"
}

variable "monitoring_ip" {
  description = "IP адрес сервера мониторинга"
  type        = string
  default     = "192.168.30.10"
}

variable "jump_ip" {
  description = "IP адрес jump-сервера"
  type        = string
  default     = "192.168.30.20"
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

# Ресурсы для биллингового сервера
variable "billing_cpu" {
  description = "Количество CPU для биллингового сервера"
  type        = number
  default     = 4
}

variable "billing_memory" {
  description = "Память для биллингового сервера (MB)"
  type        = number
  default     = 8192
}

variable "billing_disk_size" {
  description = "Размер диска для биллингового сервера"
  type        = string
  default     = "100G"
}

variable "billing_vlan_tag" {
  description = "VLAN тег для биллингового сервера"
  type        = number
  default     = null
}

# Ресурсы для веб-сервера
variable "web_cpu" {
  description = "Количество CPU для веб-сервера"
  type        = number
  default     = 2
}

variable "web_memory" {
  description = "Память для веб-сервера (MB)"
  type        = number
  default     = 4096
}

variable "web_disk_size" {
  description = "Размер диска для веб-сервера"
  type        = string
  default     = "50G"
}

variable "web_vlan_tag" {
  description = "VLAN тег для веб-сервера"
  type        = number
  default     = null
}

# Ресурсы для сервера мониторинга
variable "monitoring_cpu" {
  description = "Количество CPU для сервера мониторинга"
  type        = number
  default     = 2
}

variable "monitoring_memory" {
  description = "Память для сервера мониторинга (MB)"
  type        = number
  default     = 4096
}

variable "monitoring_disk_size" {
  description = "Размер диска для сервера мониторинга"
  type        = string
  default     = "100G"
}

variable "monitoring_vlan_tag" {
  description = "VLAN тег для сервера мониторинга"
  type        = number
  default     = null
}

# Ресурсы для jump-сервера
variable "jump_cpu" {
  description = "Количество CPU для jump-сервера"
  type        = number
  default     = 2
}

variable "jump_memory" {
  description = "Память для jump-сервера (MB)"
  type        = number
  default     = 2048
}

variable "jump_disk_size" {
  description = "Размер диска для jump-сервера"
  type        = string
  default     = "30G"
}

variable "jump_vlan_tag" {
  description = "VLAN тег для jump-сервера"
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

