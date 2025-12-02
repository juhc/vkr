# Краткое руководство по использованию

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
cd scenarios/scenario-office-organization

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
# Проверка веб-сервера
curl http://192.168.10.10:8080

# Проверка файлового сервера
smbclient //192.168.20.10/public-share -N

# Проверка базы данных
mysql -h 192.168.20.30 -u root -proot123
```

### 5. Удаление

```bash
./scripts/destroy.sh
```

## Структура проекта

```
scenario-office-organization/
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
| web-server | 192.168.10.10 | Веб-сервер | Log4Shell, устаревший Apache |
| file-server | 192.168.20.10 | Файловый сервер | Открытые шары, SMBv1 |
| db-server | 192.168.20.30 | База данных | Слабые пароли, открытый доступ |
| dns-server | 192.168.10.30 | DNS | Открытый рекурсивный DNS |

## Следующие шаги

1. Изучите документацию в `DEPLOYMENT.md`
2. Разверните инфраструктуру
3. Изучите сценарии в `machine-scenarios.md`
4. Начните практические упражнения

## Поддержка

При возникновении проблем см. раздел "Устранение проблем" в `DEPLOYMENT.md`

