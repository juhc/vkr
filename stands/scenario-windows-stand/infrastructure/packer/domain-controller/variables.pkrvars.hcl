# Переменные для Domain Controller шаблона (НЕсекретные)
#
# Общие НЕсекретные переменные:
# - ..\variables.common.pkrvars.hcl
#
# Общие СЕКРЕТЫ (токены/пароли):
# - ..\variables.secrets.pkrvars.hcl

# ISO (ВАЖНО: заранее подготовленный ISO с autounattend.xml + $WinpeDriver$ + OEM scripts)
iso_file        = "local:iso/WindowsServer_2022_unattend_dc.iso"
virtio_iso_file = "local:iso/virtio-win-0.1.285.iso"

# VM
vm_name   = "domain-controller-template"
vm_id     = 9300
cpu_cores = 2
memory    = 4096
disk_size = "80G"

# Domain
domain_name = "training.local"

