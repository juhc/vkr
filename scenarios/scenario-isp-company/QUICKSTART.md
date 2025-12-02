# Краткое руководство по использованию - ISP компания

## Быстрый старт

### 1. Подготовка системы

```bash
# Установка зависимостей (Ubuntu/Debian)
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients terraform ansible

# Добавление пользователя в группу libvirt
sudo usermod -aG libvirt $USER
newgrp libvirt

# Скачивание базового образа Ubuntu
sudo mkdir -p /var/lib/libvirt/images
cd /var/lib/libvirt/images
sudo wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

### 2. Настройка проекта

```bash
cd scenarios/scenario-isp-company

# Копирование и редактирование переменных
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
nano infrastructure/terraform/terraform.tfvars
```

### 3. Развертывание

```bash
# Автоматическое развертывание
./scripts/deploy.sh

# Или ручное развертывание
cd infrastructure/terraform
terraform init
terraform apply

cd ../ansible
ansible-playbook -i inventory.yml playbook.yml
```

### 4. Проверка

```bash
# Проверка RADIUS сервера
radtest testuser testpass 192.168.10.30 0 testing123

# Проверка DNS сервера
dig @192.168.10.40 internetplus.local

# Проверка веб-сервера
curl http://192.168.20.20

# Проверка биллинга
curl http://192.168.20.10
```

### 5. Удаление

```bash
./scripts/destroy.sh
```

## Структура проекта

```
scenario-isp-company/
├── README.md                    # Описание сценария
├── DEPLOYMENT.md               # Подробное руководство по развертыванию
├── network-topology.md         # Сетевая топология
├── machine-scenarios.md        # Сценарии для каждой машины
├── objectives.md               # Цели обучения
├── infrastructure/
│   ├── terraform/              # Terraform конфигурации
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── ansible/                # Ansible конфигурации
│       ├── inventory.yml
│       └── playbook.yml
└── scripts/
    ├── deploy.sh               # Скрипт развертывания
    └── destroy.sh              # Скрипт удаления
```

## Основные серверы

| Сервер | IP адрес | Роль | Уязвимости |
|--------|----------|------|-----------|
| pppoe-server | 192.168.10.10 | PPPoE сервер | Слабые пароли, открытые порты |
| dhcp-server | 192.168.10.20 | DHCP сервер | Отсутствие rate limiting |
| radius-server | 192.168.10.30 | RADIUS сервер | Слабый пароль БД, небезопасная конфигурация |
| dns-server | 192.168.10.40 | DNS сервер | Открытый рекурсивный DNS |
| ntp-server | 192.168.10.50 | NTP сервер | Открытый доступ |
| billing-server | 192.168.20.10 | Биллинг | SQL инъекции, слабые пароли БД |
| web-server | 192.168.20.20 | Веб-сервер | Уязвимый WordPress, SQL инъекции, XSS |
| mail-server | 192.168.20.30 | Почтовый сервер | Открытый релей, слабые пароли |
| crm-server | 192.168.20.40 | CRM | Уязвимая версия, слабые пароли |
| monitoring-server | 192.168.30.10 | Мониторинг | Слабые SNMP community strings |
| jump-server | 192.168.30.20 | Jump-сервер | Доступ по паролю, отсутствие 2FA |
| backup-server | 192.168.30.30 | Резервное копирование | Нешифрованные бэкапы |

## Сетевые сегменты

- **Клиентская сеть** (10.0.0.0/8): Подключения клиентов
- **Инфраструктурная сеть** (192.168.10.0/24): Критичные сервисы
- **Сервисная сеть** (192.168.20.0/24): Публичные сервисы
- **Управляющая сеть** (192.168.30.0/24): Управление инфраструктурой

## Следующие шаги

1. Изучите документацию в `DEPLOYMENT.md`
2. Разверните инфраструктуру
3. Изучите сценарии в `machine-scenarios.md`
4. Начните практические упражнения из `objectives.md`

## Поддержка

При возникновении проблем см. раздел "Устранение проблем" в `DEPLOYMENT.md`


