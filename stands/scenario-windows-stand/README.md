# Windows Стенд

## Описание

Стенд для обучения защите операционных систем Windows. Включает рабочую станцию Windows, Windows Server и Domain Controller.

## Состав инфраструктуры

### 1. Рабочая станция Windows
- **Возможные образы:** Windows XP, Windows 7, Windows 10, Windows 11
- **IP адрес:** `192.168.101.10`
- **Назначение:** Демонстрация уязвимостей клиентских ОС Windows

### 2. Windows Server
- **Версия:** Windows Server 2016/2019/2022
- **IP адрес:** `192.168.101.20`
- **Назначение:** Демонстрация уязвимостей серверных ОС Windows

### 3. Domain Controller (DC)
- **Версия:** Windows Server 2016/2019/2022 (с ролью AD DS)
- **IP адрес:** `192.168.101.30`
- **Назначение:** Демонстрация уязвимостей Active Directory и доменной инфраструктуры

## Сетевая топология

```
┌─────────────────────────────────────────┐
│        192.168.101.0/24                 │
│      (Windows Стенд)                     │
│                                          │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Windows WS   │  │ Windows Server│   │
│  │  .10          │  │  .20          │   │
│  │ RDP: 3389     │  │ RDP: 3389     │   │
│  └──────────────┘  └──────────────┘   │
│                                          │
│  ┌──────────────┐                       │
│  │ Domain        │                       │
│  │ Controller    │                       │
│  │  .30          │                       │
│  │ RDP: 3389     │                       │
│  │ LDAP: 389     │                       │
│  └──────────────┘                       │
└─────────────────────────────────────────┘
```

## Структура проекта

```
scenario-windows-stand/
├── README.md                    # Этот файл
├── STRUCTURE.md                 # Подробная структура проекта
└── infrastructure/             # Инфраструктура
    ├── packer/                  # Packer для создания шаблонов Windows
    │   ├── README.md           # Документация Packer
    │   ├── QUICKSTART.md       # Быстрый старт
    │   ├── windows-10/        # Шаблон Windows 10 (рабочая станция)
    │   │   ├── windows-ws.pkr.hcl
    │   │   ├── autounattend.xml
    │   │   └── variables.pkr.hcl.example
    │   ├── windows-server/     # Шаблон Windows Server
    │   │   ├── windows-server.pkr.hcl
    │   │   ├── autounattend.xml
    │   │   └── variables.pkr.hcl.example
    │   └── domain-controller/  # Шаблон Domain Controller
    │       ├── domain-controller.pkr.hcl
    │       ├── autounattend.xml
    │       └── variables.pkr.hcl.example
    ├── terraform/              # Terraform конфигурации
    │   ├── windows-10/        # Конфигурация Windows 10
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── terraform.tfvars.example
    │   ├── windows-server/    # Конфигурация Windows Server
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── terraform.tfvars.example
    │   └── domain-controller/ # Конфигурация DC
    │       ├── main.tf
    │       ├── variables.tf
    │       └── terraform.tfvars.example
    ├── ansible/                # Ansible конфигурации
    │   ├── inventory.yml      # Инвентарь машин
    │   ├── windows-10/        # Playbook для Windows 10
    │   │   └── playbook.yml
    │   ├── windows-server/    # Playbook для Windows Server
    │   │   └── playbook.yml
    │   ├── domain-controller/ # Playbook для DC
    │   │   └── playbook.yml
    │   └── group_vars/        # Переменные для групп
    │       └── all/
    │           └── vulnerabilities.yml
    └── scripts/                # Скрипты автоматизации
        └── deploy.sh          # Скрипт развертывания всего стенда
```

## Быстрый старт

### 0. Создание шаблонов Windows через Packer (рекомендуется)

Перед использованием Terraform рекомендуется создать шаблоны Windows через Packer:

```bash
# Создание шаблона рабочей станции Windows
cd infrastructure/packer/windows-10
cp variables.pkr.hcl.example variables.pkr.hcl
# Отредактируйте variables.pkr.hcl
packer init .
packer build .

# Создание шаблона Windows Server
cd ../windows-server
cp variables.pkr.hcl.example variables.pkr.hcl
# Отредактируйте variables.pkr.hcl
packer init .
packer build .

# Создание шаблона Domain Controller
cd ../domain-controller
cp variables.pkr.hcl.example variables.pkr.hcl
# Отредактируйте variables.pkr.hcl
packer init .
packer build .
```

Подробные инструкции: [Packer README](infrastructure/packer/README.md) | [Быстрый старт](infrastructure/packer/QUICKSTART.md)

### 1. Настройка Terraform переменных

Для каждой машины скопируйте пример конфигурации и заполните параметры:

```bash
# Рабочая станция Windows
cd infrastructure/terraform/windows-10
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars с вашими параметрами Proxmox
# Укажите имя шаблона, созданного через Packer (например: template_name = "windows-10-ws-template")

# Windows Server
cd ../windows-server
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars
# Укажите имя шаблона, созданного через Packer

# Domain Controller
cd ../domain-controller
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars
# Укажите имя шаблона, созданного через Packer
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
# Рабочая станция Windows
cd infrastructure/terraform/windows-10
terraform init
terraform plan
terraform apply

# Windows Server
cd ../windows-server
terraform init
terraform plan
terraform apply

# Domain Controller
cd ../domain-controller
terraform init
terraform plan
terraform apply
```

### 3. Настройка уязвимостей через Ansible

```bash
cd infrastructure/ansible

# Настройка рабочей станции Windows
ansible-playbook -i inventory.yml windows-10/playbook.yml

# Настройка Windows Server
ansible-playbook -i inventory.yml windows-server/playbook.yml

# Настройка Domain Controller
ansible-playbook -i inventory.yml domain-controller/playbook.yml
```

### 4. Настройка уязвимостей

Отредактируйте файл `infrastructure/ansible/group_vars/all/vulnerabilities.yml` для выбора уязвимостей, которые будут развернуты на каждой машине.

## Конфигурация машин

### Рабочая станция Windows

- **IP:** 192.168.101.10
- **Конфигурация:** `infrastructure/terraform/windows-10/`
- **Playbook:** `infrastructure/ansible/windows-10/playbook.yml`

### Windows Server

- **IP:** 192.168.101.20
- **Конфигурация:** `infrastructure/terraform/windows-server/`
- **Playbook:** `infrastructure/ansible/windows-server/playbook.yml`

### Domain Controller

- **IP:** 192.168.101.30
- **Конфигурация:** `infrastructure/terraform/domain-controller/`
- **Playbook:** `infrastructure/ansible/domain-controller/playbook.yml`

## Требования

- Proxmox VE
- Terraform >= 1.0
- Ansible >= 2.9
- WinRM доступ к Windows машинам
- Windows образы или шаблоны в Proxmox

## Дополнительная информация

Подробная структура проекта описана в [STRUCTURE.md](STRUCTURE.md)
