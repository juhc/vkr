# Структура проекта учебных стендов

## Общая структура

```
stands/
├── README.md                    # Главный README с описанием всех стендов
├── PROJECT_STRUCTURE.md          # Этот файл - описание структуры проекта
│
├── scenario-windows-stand/      # Windows Стенд
│   ├── README.md
│   ├── STRUCTURE.md
│   └── infrastructure/
│       ├── terraform/
│       │   ├── windows-10/        # Конфигурация Windows 10 (рабочая станция)
│       │   ├── windows-server/    # Конфигурация Windows Server
│       │   └── domain-controller/ # Конфигурация DC
│       ├── ansible/
│       │   ├── inventory.yml
│       │   ├── windows-10/
│       │   ├── windows-server/
│       │   ├── domain-controller/
│       │   └── group_vars/
│       └── scripts/
│           └── deploy.sh
│
└── scenario-linux-stand/        # Linux Стенд
    ├── README.md
    ├── STRUCTURE.md
    └── infrastructure/
        ├── terraform/
        │   ├── linux-ws/          # Конфигурация рабочей станции
        │   └── linux-server/     # Конфигурация сервера
        ├── ansible/
        │   ├── inventory.yml
        │   ├── linux-ws/
        │   ├── linux-server/
        │   └── group_vars/
        └── scripts/
            └── deploy.sh
```

---

## Принципы организации

### 1. Разделение по стендам

Каждый стенд находится в отдельной директории:
- **scenario-windows-stand/** - все, что связано с Windows
- **scenario-linux-stand/** - все, что связано с Linux

### 2. Раздельные конфигурации для каждой машины

Каждая машина имеет свою отдельную директорию:

**Windows Стенд:**
- `terraform/windows-10/` - Terraform конфигурация Windows 10
- `terraform/windows-server/` - Terraform конфигурация Windows Server
- `terraform/domain-controller/` - Terraform конфигурация DC
- `ansible/windows-10/` - Ansible playbook для Windows 10
- `ansible/windows-server/` - Ansible playbook для Windows Server
- `ansible/domain-controller/` - Ansible playbook для DC

**Linux Стенд:**
- `terraform/linux-ws/` - Terraform конфигурация рабочей станции
- `terraform/linux-server/` - Terraform конфигурация сервера
- `ansible/linux-ws/` - Ansible playbook для рабочей станции
- `ansible/linux-server/` - Ansible playbook для сервера

### 3. Централизованное управление уязвимостями

Конфигурация уязвимостей для каждого стенда находится в:
- `ansible/group_vars/all/vulnerabilities.yml`

Это позволяет управлять всеми уязвимостями из одного места.

---

## Состав стендов

### Windows Стенд

| Машина | IP | Конфигурация Terraform | Playbook Ansible |
|--------|----|----------------------|------------------|
| Рабочая станция Windows | 192.168.101.10 | `terraform/windows-10/` | `ansible/windows-10/` |
| Windows Server | 192.168.101.20 | `terraform/windows-server/` | `ansible/windows-server/` |
| Domain Controller | 192.168.101.30 | `terraform/domain-controller/` | `ansible/domain-controller/` |

### Linux Стенд

| Машина | IP | Конфигурация Terraform | Playbook Ansible |
|--------|----|----------------------|------------------|
| Рабочая станция Linux Desktop | 192.168.102.10 | `terraform/linux-ws/` | `ansible/linux-ws/` |
| Linux сервер | 192.168.102.20 | `terraform/linux-server/` | `ansible/linux-server/` |

---

## Сети

Каждый стенд использует свою отдельную сеть:

- **Windows Стенд:** 192.168.101.0/24
- **Linux Стенд:** 192.168.102.0/24

Это позволяет развертывать стенды независимо друг от друга.

---

## Файлы конфигурации

### Terraform

Для каждой машины:
- `main.tf` - основная конфигурация
- `variables.tf` - переменные
- `terraform.tfvars.example` - пример конфигурации

### Ansible

Для каждого стенда:
- `inventory.yml` - инвентарь всех машин стенда
- `group_vars/all/vulnerabilities.yml` - конфигурация уязвимостей

Для каждой машины:
- `playbook.yml` - playbook для настройки уязвимостей

---

## Скрипты автоматизации

### deploy.sh

Скрипт для автоматического развертывания всего стенда:
- Развертывание всех машин через Terraform
- Настройка уязвимостей через Ansible
- Проверка доступности машин

Находится в `infrastructure/scripts/deploy.sh` для каждого стенда.

---

## Работа с проектом

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

## Расширение проекта

### Добавление новой машины

1. Создайте директорию в `terraform/` с конфигурацией
2. Создайте директорию в `ansible/` с playbook
3. Добавьте машину в `ansible/inventory.yml`
4. Обновите `ansible/group_vars/all/vulnerabilities.yml`
5. Обновите скрипт `deploy.sh`

### Добавление нового стенда

1. Создайте директорию `scenario-<name>-stand/`
2. Скопируйте структуру из существующего стенда
3. Измените IP адреса на новую сеть
4. Обновите главный `README.md`

---

**Версия:** 1.0  
**Дата:** 2024
