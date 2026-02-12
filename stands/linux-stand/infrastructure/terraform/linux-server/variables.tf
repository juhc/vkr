# Переменные для Linux сервера

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

variable "proxmox_mgmt_bridge" {
  description = "Опционально: второй bridge для management/SSH доступа (пусто = второй интерфейс отключён)"
  type        = string
  default     = ""
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

variable "linux_server_name" {
  description = "Имя виртуальной машины"
  type        = string
  default     = "linux-server-training"
}

variable "linux_server_cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 4
}

variable "linux_server_memory" {
  description = "Объем памяти в МБ"
  type        = number
  default     = 8192
}

variable "linux_server_disk_size" {
  description = "Размер диска"
  type        = string
  default     = "100G"
}

variable "linux_server_ip" {
  description = "IP адрес Linux сервера"
  type        = string
  default     = "192.168.102.20"
}

variable "linux_server_user" {
  description = "Имя пользователя для cloud-init"
  type        = string
  default     = "ansible"
}

variable "linux_server_password" {
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

variable "mgmt_use_dhcp" {
  description = "Для второго интерфейса: если true — ipconfig1=ip=dhcp, иначе используется статический IP."
  type        = bool
  default     = false
}

variable "linux_server_mgmt_ip" {
  description = "Статический IP второго интерфейса Linux Server (используется при mgmt_use_dhcp=false)"
  type        = string
  default     = ""
}

variable "mgmt_cidr_prefix" {
  description = "Префикс сети второго интерфейса (например 24)"
  type        = number
  default     = 24
}

variable "mgmt_gateway" {
  description = "Опционально: шлюз второго интерфейса (пусто = без gw в ipconfig1)"
  type        = string
  default     = ""
}
