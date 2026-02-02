# Стенды для обучения кибербезопасности

## Обзор

Этот репозиторий содержит два учебных стенда для обучения защите операционных систем. Каждый стенд представляет собой изолированную учебную инфраструктуру (Cyber Range) с конфигурациями для каждой машины в отдельных каталогах.

## Доступные стенды

### 1. Windows Стенд (`scenario-windows-stand`)

**Описание:** Стенд для обучения защите операционных систем Windows

**Состав:**
- **Рабочая станция Windows** (192.168.101.10)
  - Возможные образы: Windows XP, Windows 7, Windows 10, Windows 11
- **Windows Server** (192.168.101.20)
  - Версии: Windows Server 2016, 2019, 2022
- **Domain Controller** (192.168.101.30)
  - Версии: Windows Server 2016, 2019, 2022 с ролью AD DS

**Сеть:** 192.168.101.0/24

**Структура:**
```
scenario-windows-stand/
├── README.md
├── STRUCTURE.md
└── infrastructure/
    ├── terraform/
    │   ├── windows-10/        # Конфигурация Windows 10 (рабочая станция)
    │   ├── windows-server/    # Конфигурация Windows Server
    │   └── domain-controller/ # Конфигурация DC
    ├── ansible/
    │   ├── inventory.yml
    │   ├── windows-10/        # Playbook для Windows 10
    │   ├── windows-server/    # Playbook для Windows Server
    │   ├── domain-controller/ # Playbook для DC
    │   └── group_vars/
    │       └── all/
    │           └── vulnerabilities.yml
    └── scripts/
        └── deploy.sh
```

---

### 2. Linux Стенд (`scenario-linux-stand`)

**Описание:** Стенд для обучения защите операционных систем Linux

**Состав:**
- **Рабочая станция Linux Desktop** (192.168.102.10)
  - Дистрибутивы: Ubuntu Desktop, Debian Desktop
- **Linux сервер** (192.168.102.20)
  - Дистрибутивы: Ubuntu Server, Debian Server, CentOS, AlmaLinux

**Сеть:** 192.168.102.0/24

**Структура:**
```
scenario-linux-stand/
├── README.md
├── STRUCTURE.md
└── infrastructure/
    ├── terraform/
    │   ├── linux-ws/      # Конфигурация рабочей станции
    │   └── linux-server/  # Конфигурация сервера
    ├── ansible/
    │   ├── inventory.yml
    │   ├── linux-ws/      # Playbook для рабочей станции
    │   ├── linux-server/  # Playbook для сервера
    │   └── group_vars/
    │       └── all/
    │           └── vulnerabilities.yml
    └── scripts/
        └── deploy.sh
```

---

## Быстрый старт

### Windows Стенд

#### Развертывание рабочей станции Windows

```bash
cd scenario-windows-stand/infrastructure/terraform/windows-10
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars с вашими параметрами Proxmox
terraform init
terraform plan
terraform apply
```

#### Развертывание Windows Server

```bash
cd scenario-windows-stand/infrastructure/terraform/windows-server
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars
terraform init
terraform plan
terraform apply
```

#### Развертывание Domain Controller

```bash
cd scenario-windows-stand/infrastructure/terraform/domain-controller
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars
terraform init
terraform plan
terraform apply
```

#### Автоматическое развертывание всего стенда

```bash
cd scenario-windows-stand/infrastructure/scripts
chmod +x deploy.sh
./deploy.sh
```

---

### Linux Стенд

#### Развертывание рабочей станции Linux

```bash
cd scenario-linux-stand/infrastructure/terraform/linux-ws
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars с вашими параметрами Proxmox
terraform init
terraform plan
terraform apply
```

#### Развертывание Linux сервера

```bash
cd scenario-linux-stand/infrastructure/terraform/linux-server
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars
terraform init
terraform plan
terraform apply
```

#### Автоматическое развертывание всего стенда

```bash
cd scenario-linux-stand/infrastructure/scripts
chmod +x deploy.sh
./deploy.sh
```

---

## Сетевая топология

```
┌─────────────────────────────────────────┐
│         Windows Стенд                    │
│        192.168.101.0/24                 │
│                                          │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Windows WS   │  │ Windows Server│   │
│  │  .10          │  │  .20          │   │
│  └──────────────┘  └──────────────┘   │
│                                          │
│  ┌──────────────┐                       │
│  │ Domain        │                       │
│  │ Controller    │                       │
│  │  .30          │                       │
│  └──────────────┘                       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         Linux Стенд                      │
│        192.168.102.0/24                  │
│                                          │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Linux WS     │  │ Linux Server │   │
│  │ (Desktop)    │  │ (Server)     │   │
│  │  .10          │  │  .20          │   │
│  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────┘
```

Каждый стенд находится в отдельной сети и может быть развернут независимо.

---

## Особенности структуры

### Раздельные конфигурации для каждой машины

Каждая машина имеет свою отдельную директорию с конфигурациями:

**Windows Стенд:**
- `terraform/windows-10/` - конфигурация Terraform для Windows 10
- `terraform/windows-server/` - конфигурация Terraform для Windows Server
- `terraform/domain-controller/` - конфигурация Terraform для DC
- `ansible/windows-10/` - Ansible playbook для Windows 10
- `ansible/windows-server/` - Ansible playbook для Windows Server
- `ansible/domain-controller/` - Ansible playbook для DC

**Linux Стенд:**
- `terraform/linux-ws/` - конфигурация Terraform для рабочей станции
- `terraform/linux-server/` - конфигурация Terraform для сервера
- `ansible/linux-ws/` - Ansible playbook для рабочей станции
- `ansible/linux-server/` - Ansible playbook для сервера

### Управление уязвимостями

Конфигурация уязвимостей находится в `ansible/group_vars/all/vulnerabilities.yml` для каждого стенда. Это позволяет:

- Выбирать, какие уязвимости будут развернуты
- Настраивать уровни сложности
- Управлять конфигурацией централизованно

---

## Требования

### Общие требования

- **Proxmox VE** - платформа виртуализации
- **Terraform** >= 1.0 - для развертывания инфраструктуры
- **Ansible** >= 2.9 - для настройки уязвимостей
- **SSH доступ** к Proxmox серверу

### Для Windows Стенда

- **WinRM** доступ к Windows машинам
- **Ansible winrm** модуль установлен
- **Windows образы** или шаблоны в Proxmox

### Для Linux Стенда

- **SSH ключи** настроены для доступа к Linux машинам
- **Linux образы** или шаблоны в Proxmox

---

## Настройка

### 1. Настройка Proxmox

Создайте API токен в Proxmox:
1. Datacenter → Permissions → API Tokens
2. Создайте токен с правами на создание VM
3. Сохраните Token ID и Secret

### 2. Настройка Terraform

Для каждой машины:
1. Скопируйте `terraform.tfvars.example` в `terraform.tfvars`
2. Заполните параметры Proxmox:
   - `proxmox_api_url`
   - `proxmox_api_token_id`
   - `proxmox_api_token_secret`
   - `proxmox_node`
   - `storage`
   - `template_name`

### 3. Настройка Ansible

1. Проверьте `inventory.yml` - убедитесь, что IP адреса и учетные данные правильные
2. Настройте `group_vars/all/vulnerabilities.yml` - выберите уязвимости для развертывания

---

## Использование

### Развертывание одной машины

```bash
cd scenario-windows-stand/infrastructure/terraform/windows-ws
terraform init
terraform apply
```

### Развертывание всего стенда

```bash
cd scenario-windows-stand/infrastructure/scripts
./deploy.sh
```

### Настройка уязвимостей

```bash
cd scenario-windows-stand/infrastructure/ansible
ansible-playbook -i inventory.yml windows-10/playbook.yml
```

---

## Документация

Каждый стенд содержит свою документацию:

- **scenario-windows-stand/README.md** - описание Windows стенда
- **scenario-windows-stand/STRUCTURE.md** - структура проекта
- **scenario-linux-stand/README.md** - описание Linux стенда
- **scenario-linux-stand/STRUCTURE.md** - структура проекта

---

## Лицензия

[Укажите лицензию]

---

**Версия:** 1.0  
**Дата:** 2024
