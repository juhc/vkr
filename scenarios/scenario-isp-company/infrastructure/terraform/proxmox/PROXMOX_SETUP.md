# Подробное руководство по настройке Proxmox

Это руководство описывает пошаговую настройку Proxmox VE для развертывания инфраструктуры ISP компании.

## Установка Proxmox VE

### Требования к серверу

- **CPU**: 4+ ядер (рекомендуется 8+)
- **RAM**: 16 GB (рекомендуется 32 GB+)
- **Диск**: 200+ GB SSD
- **Сеть**: Gigabit Ethernet

### Процесс установки

1. Скачайте ISO образ Proxmox VE с [официального сайта](https://www.proxmox.com/en/downloads)
2. Запишите на USB или используйте для загрузки сервера
3. Загрузитесь с установочного носителя
4. Следуйте инструкциям установщика
5. Запишите IP адрес, который будет назначен серверу

### Первоначальная настройка

1. Откройте веб-интерфейс: `https://your-proxmox-ip:8006`
2. Войдите с учетными данными root
3. Примите лицензию (если требуется)

## Настройка сети

### Создание сетевых мостов

Для изоляции сетей создайте отдельные мосты:

```bash
# На Proxmox сервере через SSH или консоль
nano /etc/network/interfaces
```

Добавьте конфигурацию:

```
# Основной мост для инфраструктуры
auto vmbr0
iface vmbr0 inet static
    address 192.168.10.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

# Мост для сервисной сети
auto vmbr1
iface vmbr1 inet static
    address 192.168.20.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

# Мост для управляющей сети
auto vmbr2
iface vmbr2 inet static
    address 192.168.30.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

# Мост для сети атакующего
auto vmbr3
iface vmbr3 inet static
    address 192.168.50.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
```

Примените изменения:

```bash
ifreload -a
```

## Создание шаблонов

### Шаблон Ubuntu 20.04

#### Через веб-интерфейс

1. **Datacenter → local → ISO Images**
2. Загрузите Ubuntu Cloud Image
3. **Create VM**:
   - VM ID: 9000
   - Name: ubuntu-20.04-template
   - OS: Linux, 5.x - 2.6 Kernel
4. **Hardware**:
   - Создайте диск из загруженного образа
   - Добавьте Cloud-Init Drive
5. **Cloud-Init**:
   - User: `ubuntu`
   - Password: (оставьте пустым, используйте SSH ключ)
   - DNS: 8.8.8.8
6. **Options**:
   - QEMU Guest Agent: включен
7. Запустите ВМ и дождитесь загрузки
8. **Right-click → Convert to Template**

#### Через CLI

```bash
# Скачивание образа
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Создание ВМ
qm create 9000 --name ubuntu-20.04-template --memory 2048 --net0 virtio,bridge=vmbr0

# Импорт диска
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm

# Настройка диска
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Cloud-init
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0

# QEMU Guest Agent
qm set 9000 --agent enabled=1

# Преобразование в шаблон
qm template 9000
```

### Шаблон Kali Linux

```bash
# Скачивание образа Kali
cd /var/lib/vz/template/iso
wget https://cdimage.kali.org/kali-2023.4/kali-linux-2023.4-qemu-amd64.qcow2

# Создание ВМ
qm create 9001 --name kali-linux-template --memory 4096 --net0 virtio,bridge=vmbr0

# Импорт диска
qm importdisk 9001 kali-linux-2023.4-qemu-amd64.qcow2 local-lvm

# Настройка
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
qm set 9001 --ide2 local-lvm:cloudinit
qm set 9001 --boot c --bootdisk scsi0
qm set 9001 --serial0 socket --vga serial0
qm set 9001 --agent enabled=1

# Cloud-init пользователь
qm set 9001 --ciuser kali

# Преобразование в шаблон
qm template 9001
```

## Настройка API доступа

### Создание пользователя для Terraform

1. **Datacenter → Permissions → Users → Add**
2. Заполните:
   - **User name**: `terraform`
   - **Realm**: `pve` (Proxmox VE)
   - **Password**: (создайте надежный пароль)
   - **Email**: (опционально)

### Создание API токена

1. **Datacenter → Permissions → API Tokens → Add**
2. Заполните:
   - **Token ID**: `terraform@pve!terraform-token`
   - **User**: `terraform@pve`
   - **Privilege Separation**: включите
3. Нажмите **Generate** и сохраните **Token Secret**

### Настройка прав доступа

1. **Datacenter → Permissions → Roles → Add**
2. Создайте роль `terraform-role` с правами:
   - **VM.Allocate**
   - **VM.Clone**
   - **VM.Config.CDROM**
   - **VM.Config.Disk**
   - **VM.Config.Network**
   - **VM.Monitor**
   - **VM.PowerMgmt**
   - **Datastore.Allocate**
   - **Datastore.AllocateSpace**

3. **Datacenter → Permissions → Add → User Permission**
   - **User**: `terraform@pve`
   - **Path**: `/`
   - **Role**: `terraform-role`
   - **Propagate**: включите

## Настройка хранилища

### Проверка доступных хранилищ

В веб-интерфейсе: **Datacenter → Storage**

Убедитесь, что есть хранилище с достаточным местом:
- **local-lvm** (рекомендуется для дисков ВМ)
- **local** (для ISO образов)

### Настройка хранилища (если нужно)

```bash
# Создание нового хранилища через CLI
pvesm add lvmthin lvm-thin --vgname vg-data --thinpool data
```

## Проверка настройки

### Тест подключения к API

```bash
# С вашего рабочего компьютера
curl -k -X GET \
  "https://your-proxmox-ip:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=your-secret"
```

Должен вернуться JSON с версией Proxmox.

### Тест создания ВМ через Terraform

```bash
cd scenarios/scenario-isp-company/infrastructure/terraform/proxmox
terraform init
terraform plan
```

Если все настроено правильно, Terraform покажет план создания ВМ.

## Безопасность

### Рекомендации

1. **Измените пароль root** после установки
2. **Используйте API токены** вместо паролей
3. **Ограничьте доступ** к веб-интерфейсу через firewall
4. **Включите 2FA** для административных пользователей
5. **Регулярно обновляйте** Proxmox

### Настройка firewall

```bash
# Включение firewall
systemctl enable pve-firewall
systemctl start pve-firewall

# Настройка правил через веб-интерфейс
# Datacenter → Firewall → Options
```

## Мониторинг

### Проверка ресурсов

В веб-интерфейсе: **Datacenter → Summary**

Проверьте:
- Использование CPU
- Использование RAM
- Использование диска
- Сетевой трафик

### Логи

```bash
# Логи Proxmox
tail -f /var/log/pve/tasks/active

# Логи ВМ
qm config <vmid> | grep log
```

## Резервное копирование

### Настройка бэкапов

1. **Datacenter → Backup → Add**
2. Настройте расписание и хранилище
3. Выберите ВМ для бэкапа

### Ручной бэкап

```bash
# Создание снапшота
qm snapshot <vmid> backup-$(date +%Y%m%d)

# Экспорт ВМ
vzdump <vmid> --storage local --compress gzip
```

## Дополнительные ресурсы

- [Официальная документация Proxmox](https://pve.proxmox.com/pve-docs/)
- [Terraform провайдер Proxmox](https://registry.terraform.io/providers/telmate/proxmox/latest/docs)
- [Форум Proxmox](https://forum.proxmox.com/)

