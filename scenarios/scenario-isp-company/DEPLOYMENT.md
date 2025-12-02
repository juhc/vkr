# Руководство по развертыванию инфраструктуры ISP компании

## Выбор платформы виртуализации

Инфраструктура может быть развернута на двух платформах:

1. **Proxmox VE** (рекомендуется для удаленного развертывания) - см. [terraform/proxmox/README.md](infrastructure/terraform/proxmox/README.md)
2. **libvirt/KVM** (для локального развертывания) - см. раздел ниже

Для развертывания на **Proxmox** перейдите в директорию:
```bash
cd infrastructure/terraform/proxmox
```

Следуйте инструкциям в [README.md](infrastructure/terraform/proxmox/README.md) и [PROXMOX_SETUP.md](infrastructure/terraform/proxmox/PROXMOX_SETUP.md).

---

## Развертывание на libvirt/KVM (локальное)

## Требования к системе

### Минимальные требования
- **CPU**: 12 ядер (рекомендуется 16+)
- **RAM**: 48 GB (рекомендуется 64 GB+)
- **Диск**: 300 GB свободного места (SSD рекомендуется)
- **ОС**: Ubuntu 20.04 LTS или новее, CentOS 8+, или другая Linux система с поддержкой libvirt

### Необходимое программное обеспечение
- **Terraform**: версия 1.0+
- **Ansible**: версия 4.0+
- **libvirt**: последняя версия
- **Python**: версия 3.8+
- **QEMU/KVM**: для виртуализации

## Установка зависимостей

### Ubuntu/Debian

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка libvirt и QEMU
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

# Добавление пользователя в группу libvirt
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Установка Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install terraform

# Установка Ansible
sudo apt install -y ansible python3-pip

# Установка Python библиотек
pip3 install pyyaml jinja2
```

### CentOS/RHEL

```bash
# Установка libvirt и QEMU
sudo yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install

# Запуск libvirt
sudo systemctl enable --now libvirtd

# Добавление пользователя в группу libvirt
sudo usermod -aG libvirt $USER

# Установка Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install -y terraform

# Установка Ansible
sudo yum install -y ansible python3-pip

# Установка Python библиотек
pip3 install pyyaml jinja2
```

## Подготовка базового образа

### Скачивание Ubuntu Cloud Image

```bash
# Создание директории для образов
sudo mkdir -p /var/lib/libvirt/images
cd /var/lib/libvirt/images

# Скачивание Ubuntu 20.04 Cloud Image
sudo wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Установка прав доступа
sudo chmod 644 focal-server-cloudimg-amd64.img
```

### Создание SSH ключа (если отсутствует)

```bash
# Генерация SSH ключа
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Копирование публичного ключа
cat ~/.ssh/id_rsa.pub
```

## Настройка проекта

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd vkr/scenarios/scenario-isp-company
```

### 2. Настройка переменных Terraform

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars

# Редактирование terraform.tfvars
nano terraform.tfvars
```

Пример содержимого `terraform.tfvars`:
```hcl
base_image_path = "/var/lib/libvirt/images/ubuntu-20.04-server-cloudimg-amd64.img"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
disk_pool = "default"
```

### 3. Настройка Ansible инвентаря

Если инвентарь не генерируется автоматически, создайте файл `infrastructure/ansible/inventory.yml` на основе шаблона.

## Развертывание инфраструктуры

### Автоматическое развертывание (рекомендуется)

```bash
# Использование скрипта автоматического развертывания
./scripts/deploy.sh
```

Скрипт выполнит следующие шаги:
1. Проверку наличия необходимых инструментов
2. Проверку базового образа
3. Инициализацию Terraform
4. Развертывание виртуальных машин
5. Генерацию Ansible инвентаря
6. Ожидание готовности серверов
7. Применение конфигураций через Ansible

### Ручное развертывание

#### Шаг 1: Развертывание через Terraform

```bash
cd infrastructure/terraform

# Инициализация Terraform
terraform init

# Просмотр плана развертывания
terraform plan -var-file="terraform.tfvars"

# Развертывание инфраструктуры
terraform apply -var-file="terraform.tfvars"
```

#### Шаг 2: Ожидание готовности серверов

Дождитесь полной загрузки всех виртуальных машин (обычно 3-7 минут для 12 серверов).

#### Шаг 3: Генерация Ansible инвентаря

```bash
# Экспорт IP адресов из Terraform outputs
terraform output -json > /tmp/terraform_outputs.json

# Использование скрипта генерации инвентаря (если доступен)
# или ручное создание на основе outputs
```

#### Шаг 4: Применение конфигураций через Ansible

```bash
cd ../ansible

# Проверка доступности серверов
ansible all -i inventory.yml -m ping

# Применение конфигураций
ansible-playbook -i inventory.yml playbook.yml
```

## Проверка развертывания

### Проверка виртуальных машин

```bash
# Список всех виртуальных машин
virsh list --all

# Проверка состояния сети
virsh net-list --all

# Проверка подключения к серверам
ssh ubuntu@192.168.10.30  # RADIUS server
ssh ubuntu@192.168.20.10  # Billing server
```

### Проверка сервисов

```bash
# Проверка RADIUS сервера
radtest testuser testpass 192.168.10.30 0 testing123

# Проверка DNS сервера
dig @192.168.10.40 internetplus.local

# Проверка веб-сервера
curl http://192.168.20.20

# Проверка биллинга
curl http://192.168.20.10

# Проверка базы данных
psql -h 192.168.20.10 -U billing_user -d billing_db
```

## Удаление инфраструктуры

### Автоматическое удаление

```bash
./scripts/destroy.sh
```

### Ручное удаление

```bash
cd infrastructure/terraform
terraform destroy -var-file="terraform.tfvars"
```

## Устранение проблем

### Проблема: Виртуальные машины не запускаются

**Решение**:
```bash
# Проверка статуса libvirt
sudo systemctl status libvirtd

# Перезапуск libvirt
sudo systemctl restart libvirtd

# Проверка логов
sudo journalctl -u libvirtd -f
```

### Проблема: Terraform не может подключиться к libvirt

**Решение**:
```bash
# Проверка подключения к libvirt
virsh list

# Если ошибка доступа, добавьте пользователя в группу
sudo usermod -aG libvirt $USER
newgrp libvirt
```

### Проблема: Ansible не может подключиться к серверам

**Решение**:
```bash
# Проверка SSH подключения
ssh ubuntu@<server-ip>

# Проверка инвентаря Ansible
ansible all -i inventory.yml -m ping -vvv

# Проверка SSH ключей
ssh-add ~/.ssh/id_rsa
```

### Проблема: RADIUS сервер не отвечает

**Решение**:
```bash
# Проверка статуса FreeRADIUS
sudo systemctl status freeradius

# Проверка логов
sudo tail -f /var/log/freeradius/radius.log

# Проверка подключения к базе данных
mysql -h 192.168.10.30 -u radius -p
```

### Проблема: Недостаточно места на диске

**Решение**:
```bash
# Проверка свободного места
df -h

# Очистка неиспользуемых образов
sudo virsh vol-list --pool default
sudo virsh vol-delete <volume-name> --pool default
```

## Оптимизация производительности

### Настройка CPU и памяти

Для улучшения производительности можно увеличить ресурсы виртуальных машин в файле `infrastructure/terraform/main.tf`:

```hcl
cpu    = 4  # Увеличить количество CPU
memory = 8192  # Увеличить объем памяти (MB)
```

### Использование SSD

Для лучшей производительности используйте SSD для хранения образов и дисков виртуальных машин.

### Настройка сети

Для улучшения сетевой производительности:
- Используйте виртуальные сети с bridge интерфейсами
- Настройте QoS для критичных сервисов
- Мониторьте использование пропускной способности

## Безопасность

⚠️ **ВАЖНО**: Эта инфраструктура создана для обучения и содержит намеренные уязвимости!

- Используйте только в изолированной среде
- Не подключайте к производственным сетям
- Не используйте реальные учетные данные
- Удаляйте инфраструктуру после завершения обучения
- Не используйте реальные данные клиентов

## Специфика ISP инфраструктуры

### Клиентские подключения

Инфраструктура поддерживает:
- **PPPoE**: Для клиентов с динамическими IP
- **DHCP**: Для клиентов с выделенными IP
- **Статические IP**: Для корпоративных клиентов

### Аутентификация

- **RADIUS**: Централизованная аутентификация клиентов
- **База данных**: Хранение учетных записей клиентов
- **Тарифы**: Различные скорости и лимиты трафика

### Мониторинг

- **SNMP**: Мониторинг сетевого оборудования
- **Zabbix**: Мониторинг серверов и сервисов
- **Логирование**: Централизованное логирование событий

## Дополнительные ресурсы

- [Документация Terraform](https://www.terraform.io/docs)
- [Документация Ansible](https://docs.ansible.com)
- [Документация libvirt](https://libvirt.org/docs.html)
- [Документация FreeRADIUS](https://freeradius.org/documentation/)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)

## Поддержка

При возникновении проблем:
1. Проверьте логи: `terraform apply` и `ansible-playbook`
2. Проверьте документацию по устранению проблем выше
3. Создайте issue в репозитории проекта


