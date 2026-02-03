# Переменные для Windows 10 шаблона (НЕсекретные)
#
# Общие НЕсекретные переменные:
# - ..\\variables.common.pkrvars.hcl
#
# Общие СЕКРЕТЫ (токены/пароли):
# - ..\\variables.secrets.pkrvars.hcl

# ISO настройки
# ВАЖНО: используйте ISO, который вы САМИ собрали (как в статье) и загрузили в Proxmox:
# - в корне ISO лежит autounattend.xml
# - в корне ISO лежит папка $WinpeDriver$ с VirtIO драйверами (диск+сеть)
iso_file         = "local:iso/Windows10_64bit_unattend_setupcomplete_agentfix3.iso"

# VirtIO ISO (нужно для установки qemu-guest-agent и virtio guest tools внутри Windows,
# чтобы Packer мог получить IP через агент и подключиться по WinRM)
virtio_iso_file  = "local:iso/virtio-win-0.1.285.iso"

# Вариант 2: ISO по URL (HTTP/HTTPS)
# iso_url        = "http://server/path/to/windows-10.iso"
# iso_checksum   = "sha256:checksum-here"

# Вариант 3: ISO локально в проекте (после копирования в infrastructure/packer/iso/)
# iso_url        = "file:///absolute/path/to/stands/windows-stand/infrastructure/packer/iso/windows-10.iso"

# Параметры VM (специфичные для этой машины)
vm_name     = "windows-10-ws-template"
vm_id       = 9003  # Поднимайте ID при неудачных сборках, чтобы не конфликтовать со старыми VM
cpu_cores   = 1
memory      = 2048
disk_size   = "50G"

# EFI диск (UEFI/OVMF)
efi_storage_pool = "local-lvm"

# Windows настройки
windows_edition = "Windows 10 Pro"

# Примечание: admin_username/admin_password/winrm_username/winrm_password
# берутся из:
# - ..\\variables.common.pkrvars.hcl (имена)
# - ..\\variables.secrets.pkrvars.hcl (пароли/токены)
# При необходимости можно переопределить здесь
