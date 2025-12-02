terraform {
  required_version = ">= 1.0"
  
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

# Переменные для сетей
variable "network_name" {
  description = "Имя сети"
  type        = string
}

variable "network_cidr" {
  description = "CIDR сети"
  type        = string
}

variable "network_bridge" {
  description = "Имя bridge интерфейса (опционально)"
  type        = string
  default     = ""
}

variable "dhcp_enabled" {
  description = "Включить DHCP"
  type        = bool
  default     = true
}

variable "dhcp_start" {
  description = "Начальный IP для DHCP"
  type        = string
  default     = ""
}

variable "dhcp_end" {
  description = "Конечный IP для DHCP"
  type        = string
  default     = ""
}

# Создание сети
resource "libvirt_network" "network" {
  name      = var.network_name
  mode      = var.network_bridge != "" ? "bridge" : "nat"
  bridge    = var.network_bridge != "" ? var.network_bridge : ""
  addresses = [var.network_cidr]
  dhcp {
    enabled = var.dhcp_enabled
    %{ if var.dhcp_start != "" && var.dhcp_end != "" }
    range {
      start = var.dhcp_start
      end   = var.dhcp_end
    }
    %{ endif }
  }
  dns {
    enabled = true
  }
}

# Выводы модуля
output "network_id" {
  description = "ID сети"
  value       = libvirt_network.network.id
}

output "network_name" {
  description = "Имя сети"
  value       = libvirt_network.network.name
}

output "network_bridge" {
  description = "Имя bridge интерфейса"
  value       = libvirt_network.network.bridge
}

