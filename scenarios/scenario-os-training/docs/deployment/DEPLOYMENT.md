# Руководство по развертыванию учебной инфраструктуры

> 📚 **Навигация**: См. [../README.md](../README.md) для полной навигации по документации.

## Описание

Данное руководство описывает процесс развертывания учебной инфраструктуры для обучения защите операционных систем. Инфраструктура включает три виртуальные машины в одной сети:

**⚠️ КРИТИЧЕСКИ ВАЖНО**: Все три машины должны быть в одной сети **192.168.100.0/24** с указанными IP адресами для корректной работы сценария.

- **Ubuntu Server 20.04** (192.168.100.10) - автоматическое развертывание через Terraform
- **Windows Server 2016** (192.168.100.20) - ручная установка
- **Windows 10 Pro** (192.168.100.30) - ручная установка

Все машины настроены с **заложенными уязвимостями и неправильными конфигурациями** через Ansible playbook для обучения.

## Сетевая топология

```
Учебная сеть: 192.168.100.0/24
├── Ubuntu Server:      192.168.100.10  (Linux уязвимости)
├── Windows Server 2016: 192.168.100.20 (Windows Server уязвимости)
└── Windows 10 Pro:     192.168.100.30  (Клиентские уязвимости)

Шлюз: 192.168.100.1
DNS: 8.8.8.8, 8.8.4.4
```

## Требования

### Системные требования

- **Хост-система**: Linux с поддержкой KVM (Ubuntu 20.04+ или аналогичная)
- **RAM**: Минимум 16 GB (рекомендуется 32 GB)
- **CPU**: Минимум 4 ядра (рекомендуется 8+)
- **Диск**: Минимум 200 GB свободного места
- **Сеть**: Настроенная сеть libvirt (обычно создается автоматически)

### Программное обеспечение

- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **libvirt** и **qemu-kvm**
- **virt-manager** (опционально, для GUI)
- **SSH ключи** для доступа к Ubuntu Server

### Образы ОС

1. **Ubuntu Server 20.04 Cloud Image**
   - Скачать: https://cloud-images.ubuntu.com/focal/current/
   - Файл: `focal-server-cloudimg-amd64.img`
   - Сохранить в: `/var/lib/libvirt/images/`

2. **Windows Server 2016 ISO**
   - Требуется лицензионный ISO образ
   - Сохранить в: `/var/lib/libvirt/images/`

3. **Windows 10 Pro ISO**
   - Требуется лицензионный ISO образ
   - Сохранить в: `/var/lib/libvirt/images/`

## Подготовка хост-системы

### 1. Установка необходимых пакетов

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo apt install -y terraform ansible python3-pip

# Установка Ansible коллекций для Windows
ansible-galaxy collection install ansible.windows
pip3 install pywinrm
```

### 2. Настройка libvirt

```bash
# Добавление пользователя в группу libvirt
sudo usermod -aG libvirt $USER
newgrp libvirt

# Проверка работы libvirt
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo virsh list --all
```

### 3. Подготовка SSH ключей

```bash
# Генерация SSH ключа (если еще нет)
ssh-keygen -t ed25519 -C "training@lab"

# Проверка наличия публичного ключа
cat ~/.ssh/id_ed25519.pub
```

### 4. Подготовка образов

```bash
# Создание директории для образов
sudo mkdir -p /var/lib/libvirt/images
sudo chown $USER:$USER /var/lib/libvirt/images

# Скачивание Ubuntu Cloud Image
cd /var/lib/libvirt/images
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Подготовка Windows ISO (скопировать вручную)
# cp /path/to/Win2016.iso /var/lib/libvirt/images/
# cp /path/to/Win10.iso /var/lib/libvirt/images/
```

## Развертывание инфраструктуры

### Шаг 1: Развертывание Ubuntu Server через Terraform

```bash
cd scenarios/scenario-os-training/infrastructure/terraform

# Инициализация Terraform
terraform init

# Проверка конфигурации
terraform validate

# Просмотр плана развертывания
terraform plan

# Развертывание Ubuntu Server
terraform apply

# После развертывания получите IP адрес
terraform output ubuntu_server_ip
```

### Шаг 2: Ручная установка Windows Server 2016

#### 2.1. Создание виртуальной машины

```bash
# Создание VM через virt-install
virt-install \
  --name windows-server-2016-training \
  --ram 8192 \
  --vcpus 4 \
  --disk path=/var/lib/libvirt/images/windows-server-2016.qcow2,size=100 \
  --network network=default,model=e1000 \
  --graphics vnc,listen=0.0.0.0 \
  --cdrom /var/lib/libvirt/images/Win2016.iso \
  --os-type windows \
  --os-variant win2k16
```

#### 2.2. Установка Windows Server 2016

1. Подключитесь к VNC (порт будет показан в выводе virt-install)
2. Установите Windows Server 2016
3. **КРИТИЧЕСКИ ВАЖНО**: Настройте сеть в той же подсети, что и Ubuntu Server:
   - **IP**: 192.168.100.20 (обязательно!)
   - **Маска**: 255.255.255.0
   - **Шлюз**: 192.168.100.1
   - **DNS**: 8.8.8.8, 8.8.4.4
4. Создайте пользователя Administrator с паролем `Admin123!`
5. Убедитесь, что машина видна в сети (ping 192.168.100.10 должен работать)

#### 2.3. Настройка WinRM для Ansible

```powershell
# В PowerShell на Windows Server 2016
# Включение WinRM
Enable-PSRemoting -Force

# Настройка WinRM для Basic аутентификации
winrm quickconfig -force
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Проверка
winrm enumerate winrm/config/listener
```

### Шаг 3: Ручная установка Windows 10 Pro

#### 3.1. Создание виртуальной машины

```bash
virt-install \
  --name windows-10-pro-training \
  --ram 4096 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/windows-10-pro.qcow2,size=80 \
  --network network=default,model=e1000 \
  --graphics vnc,listen=0.0.0.0 \
  --cdrom /var/lib/libvirt/images/Win10.iso \
  --os-type windows \
  --os-variant win10
```

#### 3.2. Установка Windows 10 Pro

1. Подключитесь к VNC (порт будет показан в выводе virt-install)
2. Установите Windows 10 Pro
3. **КРИТИЧЕСКИ ВАЖНО**: Настройте сеть в той же подсети, что и другие машины:
   - **IP**: 192.168.100.30 (обязательно!)
   - **Маска**: 255.255.255.0
   - **Шлюз**: 192.168.100.1
   - **DNS**: 8.8.8.8, 8.8.4.4
4. Создайте пользователя User с паролем `User123!`
5. Убедитесь, что машина видна в сети (ping 192.168.100.10 и 192.168.100.20 должны работать)

#### 3.2. Установка Windows 10 Pro

1. Подключитесь к VNC (порт будет показан в выводе virt-install)
2. Установите Windows 10 Pro
3. **КРИТИЧЕСКИ ВАЖНО**: Настройте сеть в той же подсети, что и другие машины:
   - **IP**: 192.168.100.30 (обязательно!)
   - **Маска**: 255.255.255.0
   - **Шлюз**: 192.168.100.1
   - **DNS**: 8.8.8.8, 8.8.4.4
4. Создайте пользователя User с паролем `User123!`
5. Убедитесь, что машина видна в сети (ping 192.168.100.10 и 192.168.100.20 должны работать)

#### 3.3. Настройка WinRM

```powershell
# В PowerShell на Windows 10
Enable-PSRemoting -Force
winrm quickconfig -force
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```

### Шаг 4: Проверка сетевой связности

**⚠️ ВАЖНО**: Перед настройкой уязвимостей убедитесь, что все три машины находятся в одной сети и могут общаться друг с другом.

```bash
# С Ubuntu Server (192.168.100.10) проверьте доступность Windows машин:
ping -c 3 192.168.100.20  # Windows Server 2016
ping -c 3 192.168.100.30  # Windows 10 Pro

# С Windows Server 2016 (192.168.100.20) проверьте:
ping 192.168.100.10  # Ubuntu Server
ping 192.168.100.30  # Windows 10 Pro

# С Windows 10 Pro (192.168.100.30) проверьте:
ping 192.168.100.10  # Ubuntu Server
ping 192.168.100.20  # Windows Server 2016
```

Если ping не работает, проверьте:
1. Все машины в одной сети 192.168.100.0/24
2. Правильно настроены IP адреса (10, 20, 30)
3. Брандмауэры не блокируют ICMP (для проверки)
4. Виртуальные машины подключены к одной виртуальной сети

### Шаг 5: Настройка уязвимостей через Ansible

После проверки сетевой связности настройте уязвимости на всех машинах:

```bash
cd scenarios/scenario-os-training/infrastructure/ansible

# Проверка доступности машин через Ansible
ansible all -i inventory.yml -m ping

# Развертывание уязвимостей на Ubuntu Server
ansible-playbook -i inventory.yml playbook.yml --limit ubuntu-server

# Развертывание уязвимостей на Windows машинах
ansible-playbook -i inventory.yml playbook.yml --limit windows

# Или развертывание на всех машинах сразу (рекомендуется)
ansible-playbook -i inventory.yml playbook.yml
```

**Примечание**: Ansible playbook настроит все уязвимости и неправильные конфигурации на всех трех машинах автоматически.

## Проверка развертывания

### Проверка Ubuntu Server

```bash
# Подключение к Ubuntu Server
ssh ubuntu@192.168.100.10

# Проверка уязвимостей
cat /root/VULNERABILITY_INFO.txt
ls -la /etc
ls -la /var
systemctl status fail2ban
ufw status
```

### Проверка Windows Server 2016

```powershell
# Подключение через RDP или PowerShell
# Проверка уязвимостей
Get-NetFirewallProfile | Select-Object Name, Enabled
Get-MpPreference | Select-Object DisableRealtimeMonitoring
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

### Проверка Windows 10 Pro

```powershell
# Аналогично Windows Server 2016
Get-NetFirewallProfile
Get-MpPreference
```

## Автоматизация развертывания

### Скрипт полного развертывания

Создайте файл `deploy.sh`:

```bash
#!/bin/bash
set -e

echo "=== Развертывание учебной инфраструктуры ==="

# Шаг 1: Terraform
echo "Шаг 1: Развертывание Ubuntu Server через Terraform..."
cd infrastructure/terraform
terraform init
terraform apply -auto-approve
cd ../..

# Шаг 2: Ожидание готовности Ubuntu Server
echo "Шаг 2: Ожидание готовности Ubuntu Server..."
sleep 60

# Шаг 3: Ansible для Ubuntu
echo "Шаг 3: Настройка уязвимостей на Ubuntu Server..."
cd infrastructure/ansible
ansible-playbook -i inventory.yml playbook.yml --limit ubuntu-server
cd ../..

echo "=== Развертывание завершено ==="
echo "Ubuntu Server: 192.168.100.10"
echo "Windows Server 2016: 192.168.100.20 (настроить вручную)"
echo "Windows 10 Pro: 192.168.100.30 (настроить вручную)"
```

## Устранение проблем

### Проблема: Terraform не может подключиться к libvirt

```bash
# Решение: Проверка прав доступа
sudo usermod -aG libvirt $USER
newgrp libvirt
sudo systemctl restart libvirtd
```

### Проблема: Ubuntu Server не получает IP адрес

```bash
# Решение: Проверка сети libvirt
sudo virsh net-list --all
sudo virsh net-start default
sudo virsh net-autostart default
```

### Проблема: Ansible не может подключиться к Windows

```powershell
# Решение: Проверка WinRM на Windows
winrm enumerate winrm/config/listener
# Убедитесь, что WinRM слушает на правильном порту
```

### Проблема: Недостаточно памяти

```bash
# Решение: Уменьшите выделение памяти в Terraform
# Измените memory в main.tf на меньшее значение
```

## Удаление инфраструктуры

### Удаление через Terraform

```bash
cd scenarios/scenario-os-training/infrastructure/terraform
terraform destroy
```

### Удаление Windows машин вручную

```bash
# Остановка и удаление VM
sudo virsh destroy windows-server-2016-training
sudo virsh undefine windows-server-2016-training
sudo virsh destroy windows-10-pro-training
sudo virsh undefine windows-10-pro-training

# Удаление дисков
sudo rm /var/lib/libvirt/images/windows-server-2016.qcow2
sudo rm /var/lib/libvirt/images/windows-10-pro.qcow2
```

## Дополнительные ресурсы

- [Документация Terraform](https://www.terraform.io/docs)
- [Документация Ansible](https://docs.ansible.com/)
- [Документация libvirt](https://libvirt.org/docs.html)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)

