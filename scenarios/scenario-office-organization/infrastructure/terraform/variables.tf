# Terraform переменные для сценария офисной организации

variable "base_image_path" {
  description = "Путь к базовому образу Ubuntu 20.04 Cloud Image"
  type        = string
  default     = "/var/lib/libvirt/images/ubuntu-20.04-server-cloudimg-amd64.img"
}

variable "ssh_public_key_path" {
  description = "Путь к SSH публичному ключу"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "disk_pool" {
  description = "Имя пула дисков libvirt"
  type        = string
  default     = "default"
}

# Примеры значений для terraform.tfvars
# base_image_path = "/var/lib/libvirt/images/ubuntu-20.04-server-cloudimg-amd64.img"
# ssh_public_key_path = "~/.ssh/id_rsa.pub"
# disk_pool = "default"

