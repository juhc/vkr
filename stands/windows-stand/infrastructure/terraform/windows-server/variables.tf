# Переменные для Windows Server

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

variable "proxmox_pool" {
  description = "Опционально: Proxmox pool для автоматической привязки ВМ (пусто = без pool)"
  type        = string
  default     = ""
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

variable "windows_server_name" {
  description = "Имя виртуальной машины"
  type        = string
  default     = "windows-server-training"
}

variable "windows_server_cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 4
}

variable "windows_server_memory" {
  description = "Объем памяти в МБ"
  type        = number
  default     = 8192
}

variable "windows_server_disk_size" {
  description = "Размер диска"
  type        = string
  default     = "100G"
}

variable "windows_server_ip" {
  description = "IP адрес Windows Server"
  type        = string
  default     = "192.168.101.20"
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