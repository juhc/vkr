variable "proxmox_api_url" {
  description = "URL API Proxmox (например, https://pve.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Имя узла Proxmox"
  type        = string
  default     = "pve"
}

variable "ssh_public_key" {
  description = "SSH публичный ключ для Ubuntu Server"
  type        = string
  default     = ""
}

variable "template_name" {
  description = "Имя шаблона Ubuntu Server в Proxmox (должен быть создан заранее)"
  type        = string
  default     = "ubuntu-20.04-template"
}

variable "storage" {
  description = "Имя хранилища данных Proxmox"
  type        = string
  default     = "local-lvm"
}

