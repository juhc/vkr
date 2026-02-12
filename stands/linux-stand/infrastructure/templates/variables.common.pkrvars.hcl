# Общие НЕсекретные переменные для Packer (Linux стенд)
#
# 1) Скопируйте в variables.common.pkrvars.hcl
# 2) НЕ храните здесь токены/пароли — для этого есть variables.secrets.pkrvars.hcl

# Proxmox
proxmox_api_url  = "https://192.168.0.150:8006/api2/json"
proxmox_node     = "pve"

# Storage
iso_storage_pool = "local"
storage_pool     = "local-lvm"
efi_storage_pool = "local-lvm"

# Network
proxmox_bridge   = "vmbr0"

