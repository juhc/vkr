# Linux Стенд

## Описание

Стенд для обучения защите операционных систем Linux. Включает рабочую станцию без сервера и рабочую станцию с сервером.

## Состав инфраструктуры

### 1. Рабочая станция без сервера
- **Возможные дистрибутивы:** Ubuntu Desktop, Debian Desktop
- **IP адрес:** `192.168.102.10`
- **Назначение:** Демонстрация уязвимостей клиентских ОС Linux

### 2. Рабочая станция с сервером
- **Возможные дистрибутивы:** Ubuntu Server, Debian Server, CentOS, AlmaLinux
- **IP адрес:** `192.168.102.20`
- **Назначение:** Демонстрация уязвимостей серверных ОС Linux и сервисов

## Сетевая топология

```
┌─────────────────────────────────────────┐
│        192.168.102.0/24                 │
│       (Linux Стенд)                      │
│                                          │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Linux WS     │  │ Linux Server │   │
│  │ (Desktop)    │  │ (Server)     │   │
│  │  .10          │  │  .20          │   │
│  │ SSH: 22       │  │ SSH: 22       │   │
│  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────┘
```

## Структура проекта

```
linux-stand/
├── README.md                    # Этот файл
├── STRUCTURE.md                 # Подробная структура проекта
└── infrastructure/             # Инфраструктура
    ├── packer/                 # Packer шаблоны (создание template в Proxmox)
    │   ├── linux-client/
    │   ├── linux-server/
    │   ├── scripts/
    │   ├── variables.common.pkrvars.hcl.example
    │   └── variables.secrets.pkrvars.hcl.example
    ├── terraform/              # Terraform конфигурации
    │   ├── linux-ws/          # Конфигурация рабочей станции
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── terraform.tfvars.example
    │   └── linux-server/      # Конфигурация сервера
    │       ├── main.tf
    │       ├── variables.tf
    │       └── terraform.tfvars.example
    ├── ansible/                # Ansible конфигурации
    │   ├── inventory.yml      # Инвентарь машин
    │   ├── linux-ws/          # Playbook для рабочей станции
    │   │   └── playbook.yml
    │   ├── linux-server/      # Playbook для сервера
    │   │   └── playbook.yml
    │   └── group_vars/        # Переменные для групп
    │       └── all/
    │           └── vulnerabilities.yml
    └── scripts/                # Скрипты автоматизации
        └── deploy.sh          # Скрипт развертывания всего стенда
```

## Быстрый старт

### 1. Настройка Terraform переменных

Для каждой машины скопируйте пример конфигурации и заполните параметры:

```bash
# Рабочая станция Linux
cd infrastructure/terraform/linux-ws
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars с вашими параметрами Proxmox

# Linux сервер
cd ../linux-server
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars
```

### 2. Развертывание инфраструктуры

#### Автоматическое развертывание всего стенда:

```bash
cd infrastructure/scripts
chmod +x deploy.sh
./deploy.sh
```

#### Ручное развертывание каждой машины:

```bash
# Рабочая станция Linux
cd infrastructure/terraform/linux-ws
terraform init
terraform plan
terraform apply

# Linux сервер
cd ../linux-server
terraform init
terraform plan
terraform apply
```

### 3. Настройка уязвимостей через Ansible

```bash
cd infrastructure/ansible

# Настройка рабочей станции Linux
ansible-playbook -i inventory.yml linux-ws/playbook.yml

# Настройка Linux сервера
ansible-playbook -i inventory.yml linux-server/playbook.yml
```

### 4. Настройка уязвимостей

Отредактируйте файл `infrastructure/ansible/group_vars/all/vulnerabilities.yml` для выбора уязвимостей, которые будут развернуты на каждой машине.

## Конфигурация машин

### Рабочая станция Linux Desktop

- **IP:** 192.168.102.10
- **Дистрибутивы:** Ubuntu Desktop, Debian Desktop
- **Конфигурация:** `infrastructure/terraform/linux-ws/`
- **Playbook:** `infrastructure/ansible/linux-ws/playbook.yml`

### Linux сервер

- **IP:** 192.168.102.20
- **Дистрибутивы:** Ubuntu Server, Debian Server, CentOS, AlmaLinux
- **Конфигурация:** `infrastructure/terraform/linux-server/`
- **Playbook:** `infrastructure/ansible/linux-server/playbook.yml`

## Требования

- Proxmox VE
- Terraform >= 1.0
- Ansible >= 2.9
- SSH доступ к Linux машинам
- SSH ключи настроены
- Linux образы или шаблоны в Proxmox

## (Опционально) Создание шаблонов через Packer

Если хотите создавать **template** через Packer (вместо ручной подготовки шаблонов), используйте:
`infrastructure/templates/` (см. `infrastructure/templates/README.md`).

## Дополнительная информация

Подробная структура проекта описана в [STRUCTURE.md](STRUCTURE.md)
