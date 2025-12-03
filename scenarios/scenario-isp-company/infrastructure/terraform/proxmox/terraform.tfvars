# Пример конфигурации для развертывания на Proxmox
# Скопируйте этот файл в terraform.tfvars и заполните своими значениями

# Настройки Proxmox API
proxmox_api_url          = "https://proxmox.example.com:8006/api2/json"
proxmox_api_token_id     = "terraform@pve!terraform-token"
proxmox_api_token_secret = "your-token-secret-here"
proxmox_tls_insecure     = false  # Установите true только для самоподписанных сертификатов в dev

# Узел Proxmox
proxmox_target_node = "proxmox-node-1"

# Шаблоны
proxmox_template_name     = "ubuntu-20.04-template"
proxmox_kali_template_name = "kali-linux-template"

# Хранилище
proxmox_disk_storage = "local-lvm"

# Сетевые настройки
network_bridge  = "vmbr0"
network_gateway = "192.168.10.1"
dns_servers     = ["8.8.8.8", "8.8.4.4"]
domain          = "internetplus.local"

# SSH настройки
# Вариант 1: Путь к файлу с ключом (рекомендуется)
ssh_public_key_file = "~/.ssh/id_rsa.pub"

# Вариант 2: Прямой ключ (альтернатива)
# ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."

ssh_user = "ubuntu"

# IP адреса машин
radius_ip    = "192.168.10.10"
billing_ip   = "192.168.20.10"
web_ip       = "192.168.20.20"
monitoring_ip = "192.168.30.10"
jump_ip      = "192.168.30.20"
kali_ip      = "192.168.50.10"

# Ресурсы для RADIUS сервера
radius_cpu     = 2
radius_memory  = 4096
radius_disk_size = "50G"

# Ресурсы для биллингового сервера
billing_cpu     = 4
billing_memory  = 8192
billing_disk_size = "100G"

# Ресурсы для веб-сервера
web_cpu     = 2
web_memory  = 4096
web_disk_size = "50G"

# Ресурсы для сервера мониторинга
monitoring_cpu     = 2
monitoring_memory  = 4096
monitoring_disk_size = "100G"

# Ресурсы для jump-сервера
jump_cpu     = 2
jump_memory  = 2048
jump_disk_size = "30G"

# Ресурсы для Kali Linux
kali_cpu     = 4
kali_memory  = 8192
kali_disk_size = "100G"

# Включение/отключение машин (для тестирования с ограниченными ресурсами)
# Установите false для машин, которые не нужно создавать
enable_radius_server    = true
enable_billing_server   = false
enable_web_server       = false
enable_monitoring_server = false
enable_jump_server      = false
enable_kali_attacker     = false

# Для запуска только одной машины, установите все в false, кроме нужной:
# enable_radius_server    = true
# enable_billing_server   = false
# enable_web_server       = false
# enable_monitoring_server = false
# enable_jump_server      = false
# enable_kali_attacker     = false

# VLAN теги (опционально, оставьте null если не используете)
# radius_vlan_tag    = null
# billing_vlan_tag   = null
# web_vlan_tag       = null
# monitoring_vlan_tag = null
# jump_vlan_tag      = null
# kali_vlan_tag      = null

