# Переменные для Domain Controller

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

variable "proxmox_bridge" {
  description = "Bridge в Proxmox (например vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "template_name" {
  description = "Имя шаблона для клонирования (пустое для создания из ISO)"
  type        = string
  default     = ""
}

variable "storage" {
  description = "Имя хранилища Proxmox"
  type        = string
}

variable "dc_name" {
  description = "Имя виртуальной машины"
  type        = string
  default     = "domain-controller-training"
}

variable "dc_cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 4
}

variable "dc_memory" {
  description = "Объем памяти в МБ"
  type        = number
  default     = 8192
}

variable "dc_disk_size" {
  description = "Размер диска"
  type        = string
  default     = "100G"
}

variable "dc_ip" {
  description = "IP адрес Domain Controller"
  type        = string
  default     = "192.168.101.30"
}

variable "domain_name" {
  description = "Имя домена Active Directory"
  type        = string
  default     = "training.local"
}

# Админ-доступ (для администраторов стенда)
variable "admin_user" {
  description = "Пользователь с админскими правами (должен существовать в шаблоне)"
  type        = string
  default     = "ansible"
}

variable "bootstrap_admin_password" {
  description = "Пароль, который 'вшит' в шаблон (нужен для первичного входа/смены)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "admin_password" {
  description = "Желаемый пароль администратора для этой VM (если пусто — не меняем)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "admin_ssh_public_key" {
  description = "Опционально: публичный SSH ключ для admin_user (добавится в authorized_keys через SSH)."
  type        = string
  default     = ""
}