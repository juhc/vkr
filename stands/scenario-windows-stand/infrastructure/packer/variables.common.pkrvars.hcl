# Общие НЕсекретные переменные для всех Packer конфигураций (Windows)
#
# НЕ храните здесь токены/пароли — для этого есть variables.secrets.pkrvars.hcl

# Proxmox
proxmox_api_url  = "https://127.0.0.1:8006/api2/json"
proxmox_node     = "pve"

# Storage
iso_storage_pool = "local"
storage_pool     = "local-lvm"
efi_storage_pool = "local-lvm"

# Network
proxmox_bridge   = "vmbr0"

# Accounts (имена — не секрет)
admin_username   = "Administrator"
winrm_username   = "Administrator"

