# Проверка вложенной виртуализации в VirtualBox

## Шаг 1: Проверка настроек VirtualBox для VM Proxmox

1. Откройте VirtualBox
2. Выберите VM с Proxmox
3. Нажмите "Настройки" (Settings)
4. Перейдите в раздел **Система → Ускорение**
5. Убедитесь, что включены:
   - ✅ **Включить VT-x/AMD-V** (Enable VT-x/AMD-V)
   - ✅ **Включить вложенную виртуализацию VT-x/AMD-V** (Enable Nested VT-x/AMD-V)
   - ✅ **Включить PAE/NX** (если доступно)

## Шаг 2: Проверка через командную строку VirtualBox

Выполните в PowerShell (замените "Proxmox-VM" на имя вашей VM):

```powershell
# Проверка текущих настроек
VBoxManage showvminfo "Proxmox-VM" | findstr "Nested"

# Включение вложенной виртуализации (если не включена)
VBoxManage modifyvm "Proxmox-VM" --nested-hw-virt on

# Включение VT-x/AMD-V (если не включено)
VBoxManage modifyvm "Proxmox-VM" --paravirtprovider kvm
```

## Шаг 3: Перезагрузка VM Proxmox

**ВАЖНО:** После изменения настроек VirtualBox необходимо:
1. Полностью выключить VM Proxmox (не suspend, а shutdown)
2. Запустить VM заново
3. Дождаться полной загрузки Proxmox

## Шаг 4: Проверка внутри Proxmox

После перезагрузки выполните на хосте Proxmox:

```bash
# Проверка поддержки виртуализации
egrep -c '(vmx|svm)' /proc/cpuinfo
# Должно быть > 0

# Проверка модулей KVM
lsmod | grep kvm
# Должны быть модули kvm_intel или kvm_amd

# Проверка устройства KVM
ls -l /dev/kvm
# Должен существовать файл /dev/kvm

# Проверка, что Proxmox видит виртуализацию
systemd-detect-virt
```

## Шаг 5: Если все еще не работает

1. Убедитесь, что хостовая система (Windows) поддерживает виртуализацию:
   - Проверьте в BIOS/UEFI, включена ли виртуализация на физическом хосте
   - В Windows: `systeminfo | findstr /C:"Hyper-V"`
   
2. Проверьте версию VirtualBox:
   ```powershell
   VBoxManage --version
   ```
   Должна быть 7.2.6 или новее

3. Попробуйте изменить тип виртуализации в настройках VM:
   - Система → Ускорение → Тип виртуализации: **KVM** или **Hyper-V**

## Альтернативное решение

Если вложенная виртуализация все еще не работает, можно попробовать использовать **QEMU builder** вместо Proxmox builder в Packer, но это потребует изменения конфигурации.
