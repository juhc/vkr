# Чек-лист проверки развертывания инфраструктуры

> 📚 **Навигация**: См. [../README.md](../README.md) для полной навигации по документации.

## Предварительная проверка

### Системные требования
- [ ] Хост-система с поддержкой KVM
- [ ] Минимум 16 GB RAM свободно
- [ ] Минимум 200 GB свободного места на диске
- [ ] Terraform >= 1.0 установлен
- [ ] Ansible >= 2.9 установлен
- [ ] libvirt и qemu-kvm установлены и работают

### Образы ОС
- [ ] Ubuntu Server 20.04 Cloud Image скачан
- [ ] Windows Server 2016 ISO доступен (для ручной установки)
- [ ] Windows 10 Pro ISO доступен (для ручной установки)

### Сеть
- [ ] Сеть libvirt "default" создана и активна
- [ ] Проверка: `sudo virsh net-list --all`

### SSH ключи
- [ ] SSH публичный ключ сгенерирован
- [ ] Проверка: `cat ~/.ssh/id_rsa.pub` или `cat ~/.ssh/id_ed25519.pub`

## Проверка Terraform конфигурации

### Файлы
- [ ] `terraform/main.tf` существует
- [ ] `terraform/variables.tf` существует (если используется)
- [ ] `terraform/terraform.tfvars.example` существует

### Валидация
```bash
cd infrastructure/terraform
terraform init
terraform validate
terraform fmt -check
```

- [ ] Terraform инициализирован без ошибок
- [ ] Конфигурация валидна
- [ ] Форматирование корректно

### План развертывания
```bash
terraform plan
```

- [ ] План создается без ошибок
- [ ] Планируется создание 1 VM (Ubuntu Server)
- [ ] Все переменные определены

## Проверка Ansible конфигурации

### Файлы
- [ ] `ansible/inventory.yml` существует
- [ ] `ansible/playbook.yml` существует

### Inventory
```bash
cd infrastructure/ansible
ansible-inventory -i inventory.yml --list
```

- [ ] Inventory файл валиден
- [ ] Определены группы: `linux`, `windows`
- [ ] IP адреса указаны правильно:
  - Ubuntu Server: 192.168.100.10
  - Windows Server 2016: 192.168.100.20
  - Windows 10 Pro: 192.168.100.30

### Синтаксис playbook
```bash
ansible-playbook --syntax-check -i inventory.yml playbook.yml
```

- [ ] Синтаксис playbook корректен
- [ ] Нет ошибок YAML

### Проверка подключения (после развертывания VM)
```bash
ansible all -i inventory.yml -m ping
```

- [ ] Ubuntu Server отвечает на ping
- [ ] Windows машины отвечают (если настроены)

## Проверка развертывания Ubuntu Server

### Terraform apply
```bash
cd infrastructure/terraform
terraform apply
```

- [ ] Terraform успешно создал VM
- [ ] VM запущена: `sudo virsh list --all`
- [ ] Получен IP адрес: `terraform output ubuntu_server_ip`

### Подключение к серверу
```bash
ssh ubuntu@192.168.100.10
```

- [ ] SSH подключение работает
- [ ] Можно выполнить команды с sudo

### Проверка базовой конфигурации
```bash
# На Ubuntu Server
hostname
ip addr show
cat /etc/os-release
```

- [ ] Hostname установлен правильно
- [ ] IP адрес: 192.168.100.10
- [ ] ОС: Ubuntu 20.04

## Проверка настройки уязвимостей через Ansible

### Выполнение playbook
```bash
cd infrastructure/ansible
ansible-playbook -i inventory.yml playbook.yml --limit ubuntu-server
```

- [ ] Playbook выполнен без критических ошибок
- [ ] Все задачи выполнены (или пропущены с ожидаемыми причинами)

### Проверка уязвимостей на Ubuntu Server

#### 1. Управление аккаунтами
```bash
# На Ubuntu Server
cat /etc/security/pwquality.conf | grep minlen
chage -l admin
sudo cat /etc/sudoers.d/vulnerable
```

- [ ] PAM-ограничения отключены (minlen = 1)
- [ ] Пароли без срока действия
- [ ] Широкие sudo права настроены

#### 2. SSH конфигурация
```bash
grep -E "PermitRootLogin|PasswordAuthentication|MaxAuthTries" /etc/ssh/sshd_config
systemctl status fail2ban
```

- [ ] PermitRootLogin yes
- [ ] PasswordAuthentication yes
- [ ] MaxAuthTries 1000
- [ ] fail2ban отключен

#### 3. Firewall
```bash
ufw status
iptables -L
```

- [ ] UFW отключен
- [ ] iptables правила разрешают все

#### 4. Обновления
```bash
ls /etc/apt/apt.conf.d/20auto-upgrades
cat /etc/apt/apt.conf.d/50unattended-upgrades | grep Automatic-Reboot
```

- [ ] Автоматические обновления отключены

#### 5. Права доступа
```bash
ls -la /etc
ls -la /var
ls -la /home
```

- [ ] Неправильные права на системные директории (777)

#### 6. Службы
```bash
systemctl status cups
systemctl status avahi-daemon
systemctl status apparmor
```

- [ ] Лишние службы включены
- [ ] AppArmor отключен

#### 7. Docker
```bash
groups
docker ps
cat /etc/docker/daemon.json
```

- [ ] Пользователи в группе docker
- [ ] Docker socket доступен

#### 8. Kernel hardening
```bash
sysctl kernel.dmesg_restrict
sysctl kernel.randomize_va_space
```

- [ ] Kernel hardening отключен
- [ ] ASLR отключен

#### 9. Информационный файл
```bash
cat /root/VULNERABILITY_INFO.txt
```

- [ ] Файл с описанием уязвимостей создан

## Проверка Windows машин (если установлены)

### Windows Server 2016

#### Подключение
```powershell
# С хоста
Test-NetConnection -ComputerName 192.168.100.20 -Port 5985
```

- [ ] WinRM доступен (порт 5985)

#### Проверка уязвимостей
```powershell
# На Windows Server 2016
Get-NetFirewallProfile | Select-Object Name, Enabled
Get-MpPreference | Select-Object DisableRealtimeMonitoring
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

- [ ] Брандмауэр отключен
- [ ] Windows Defender отключен
- [ ] SMBv1 включен

### Windows 10 Pro

Аналогично Windows Server 2016 (IP: 192.168.100.30)

## Итоговая проверка

### Сетевая связность
```bash
# С Ubuntu Server
ping -c 3 192.168.100.20  # Windows Server
ping -c 3 192.168.100.30  # Windows 10
```

- [ ] Все машины доступны в сети

### Ansible проверка всех машин
```bash
cd infrastructure/ansible
ansible all -i inventory.yml -m ping
ansible all -i inventory.yml -m setup
```

- [ ] Все машины отвечают на Ansible команды

### Документация
- [ ] DEPLOYMENT.md прочитан
- [ ] QUICKSTART.md прочитан
- [ ] Все шаги выполнены

## Известные проблемы и решения

### Проблема: Terraform не может создать VM
**Решение**: Проверьте права доступа к libvirt
```bash
sudo usermod -aG libvirt $USER
newgrp libvirt
```

### Проблема: Ubuntu Server не получает IP
**Решение**: Проверьте сеть libvirt
```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

### Проблема: Ansible не может подключиться к Windows
**Решение**: Проверьте WinRM на Windows
```powershell
winrm enumerate winrm/config/listener
```

## Следующие шаги

После успешной проверки:
1. Начните обучение с обнаружения уязвимостей
2. Используйте материалы из `overview/machine-scenarios.md`
3. Выполняйте задания по исправлению уязвимостей
4. Документируйте результаты

