# Переменные для рабочей станции Linux (Desktop)

variable "proxmox_api_url" {
  description = "URL API Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Token ID для API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Token Secret для API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Имя узла Proxmox"
  type        = string
}

variable "template_name" {
  description = "Имя шаблона для клонирования"
  type        = string
}

variable "storage" {
  description = "Имя хранилища Proxmox"
  type        = string
}

variable "proxmox_bridge" {
  description = "Bridge в Proxmox (например vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "use_dhcp" {
  description = "Если true — cloud-init получит IP по DHCP (ipconfig0=ip=dhcp). Если false — используется статический IP."
  type        = bool
  default     = false
}

variable "cidr_prefix" {
  description = "Префикс сети для статических IP (например 24 для /24)"
  type        = number
  default     = 24
}

variable "linux_ws_name" {
  description = "Имя виртуальной машины"
  type        = string
  default     = "linux-ws-training"
}

variable "linux_ws_cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 2
}

variable "linux_ws_memory" {
  description = "Объем памяти в МБ"
  type        = number
  default     = 4096
}

variable "linux_ws_disk_size" {
  description = "Размер диска"
  type        = string
  default     = "50G"
}

variable "linux_ws_ip" {
  description = "IP адрес рабочей станции Linux"
  type        = string
  default     = "192.168.102.10"
}

variable "linux_ws_user" {
  description = "Имя пользователя для cloud-init"
  type        = string
  default     = "ansible"
}

variable "linux_ws_password" {
  description = "Пароль для cloud-init пользователя (нужен для входа в консоль/SSH по паролю; рекомендуется использовать SSH ключи). Пусто = не задавать."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH публичный ключ (пустое для автоматического определения)"
  type        = string
  default     = ""
}

variable "gateway" {
  description = "IP адрес шлюза"
  type        = string
  default     = "192.168.102.1"
}

variable "nameserver" {
  description = "DNS сервер"
  type        = string
  default     = "8.8.8.8"
}
