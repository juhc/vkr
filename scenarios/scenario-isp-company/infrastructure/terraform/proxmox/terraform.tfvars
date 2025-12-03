# Пример конфигурации для развертывания на Proxmox
# Скопируйте этот файл в terraform.tfvars и заполните своими значениями

# Настройки Proxmox API
proxmox_api_url          = "https://127.0.0.1:8006/api2/json"
proxmox_api_token_id     = "root@pam!terraform"
proxmox_api_token_secret = "37e2eee7-1a9d-4fa5-9155-13b8b6ffee4e"
proxmox_tls_insecure     = true  # Установите true для самоподписанных сертификатов (для локального тестирования)

# Узел Proxmox
proxmox_target_node = "pve"

# Шаблоны
proxmox_template_name     = "test"
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
services_ip  = "192.168.20.10"  # Объединенный биллинг + веб
management_ip = "192.168.30.10"  # Объединенный мониторинг + jump
admin_workstation_ip = "192.168.30.20"  # Перемещен на освободившийся IP
kali_ip      = "192.168.50.10"

# Ресурсы для RADIUS сервера
radius_cpu     = 2
radius_memory  = 4096
radius_disk_size = "50G"

# Ресурсы для сервера сервисов (объединенный биллинг + веб)
services_cpu     = 4
services_memory  = 8192
services_disk_size = "150G"

# Ресурсы для сервера управления (объединенный мониторинг + jump)
management_cpu     = 4
management_memory  = 6144
management_disk_size = "130G"

# Ресурсы для компьютера администратора
admin_workstation_cpu     = 2
admin_workstation_memory  = 4096
admin_workstation_disk_size = "50G"

# Ресурсы для Kali Linux
kali_cpu     = 4
kali_memory  = 8192
kali_disk_size = "100G"

# Включение/отключение машин (для тестирования с ограниченными ресурсами)
# Установите false для машин, которые не нужно создавать
enable_radius_server    = true
enable_services_server  = false  # Объединенный биллинг + веб
enable_management_server = false  # Объединенный мониторинг + jump
enable_admin_workstation = false
enable_kali_attacker     = false

# Для запуска только одной машины, установите все в false, кроме нужной:
# enable_radius_server    = true
# enable_services_server   = false
# enable_management_server = false
# enable_admin_workstation = false
# enable_kali_attacker     = false

# VLAN теги (опционально, оставьте null если не используете)
# radius_vlan_tag    = null
# services_vlan_tag  = null
# management_vlan_tag = null
# admin_workstation_vlan_tag = null
# kali_vlan_tag      = null

