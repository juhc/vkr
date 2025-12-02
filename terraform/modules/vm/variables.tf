variable "vm_name" {
  description = "Имя виртуальной машины"
  type        = string
}

variable "vm_count" {
  description = "Количество виртуальных машин"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "Количество CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Объем памяти в MB"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Размер диска в GB"
  type        = number
  default     = 50
}

variable "disk_pool" {
  description = "Имя пула дисков libvirt"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Имя сети libvirt"
  type        = string
}

variable "ip_address" {
  description = "IP адрес виртуальной машины"
  type        = string
  default     = ""
}

variable "netmask" {
  description = "Маска подсети"
  type        = string
  default     = "255.255.255.0"
}

variable "gateway" {
  description = "Шлюз по умолчанию"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Список DNS серверов"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "hostname" {
  description = "Имя хоста"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Домен"
  type        = string
  default     = "techservice.local"
}

variable "base_image_path" {
  description = "Путь к базовому образу"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH публичный ключ для доступа"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Cloud-init user data"
  type        = string
  default     = ""
}

