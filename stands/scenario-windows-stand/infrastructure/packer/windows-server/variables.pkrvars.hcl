# Переменные для Windows Server шаблона (НЕсекретные)
#
# Общие НЕсекретные переменные:
# - ..\variables.common.pkrvars.hcl
#
# Общие СЕКРЕТЫ (токены/пароли):
# - ..\variables.secrets.pkrvars.hcl

# ISO (ВАЖНО: заранее подготовленный ISO с autounattend.xml + $WinpeDriver$ + OEM scripts)
iso_file        = "local:iso/WindowsServer_2022_unattend.iso"
virtio_iso_file = "local:iso/virtio-win-0.1.285.iso"

# VM
vm_name   = "windows-server-template"
vm_id     = 9200
cpu_cores = 2
memory    = 4096
disk_size = "80G"

# Windows Server edition (внутри ISO) — используйте то, что реально есть в вашем install.wim
windows_edition = "Windows Server 2022 Standard"

