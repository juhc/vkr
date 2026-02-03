# Переменные для Windows 11 шаблона (НЕсекретные)
#
# Общие НЕсекретные переменные:
# - ..\variables.common.pkrvars.hcl
#
# Общие СЕКРЕТЫ (токены/пароли):
# - ..\variables.secrets.pkrvars.hcl

# ISO (ВАЖНО: заранее подготовленный ISO с autounattend.xml + $WinpeDriver$ + OEM scripts)
iso_file        = "local:iso/Windows11_25H2_unattend.iso"
virtio_iso_file = "local:iso/virtio-win-0.1.285.iso"

# VM
vm_name   = "windows-11-template"
vm_id     = 9100
cpu_cores = 2
memory    = 4096
disk_size = "60G"

