# Структура проекта windows-stand

## 📁 Общая структура

```
windows-stand/
│
├── README.md                          # Главный README стенда
│
├── docs/                              # 📚 Документация
│   ├── overview/                      # Обзор сценария
│   ├── deployment/                    # Развертывание
│   └── learning/                      # Методические материалы
│
└── infrastructure/                     # 🔧 Инфраструктура и автоматизация
    │
    ├── packer/                         # 📦 Packer для создания шаблонов Windows
    │   ├── README.md                  # Документация Packer
    │   ├── QUICKSTART.md              # Быстрый старт
    │   ├── variables.pkr.hcl.example  # Общие переменные (Proxmox API, токены и т.д.)
    │   ├── build-example.sh           # Скрипт автоматической сборки
    │   ├── iso/                       # 📀 Директория для ISO образов Windows
    │   │   ├── README.md              # Инструкции по работе с ISO
    │   │   └── .gitignore             # Игнорировать ISO файлы в Git
    │   ├── windows-10/                # Шаблон Windows 10 (рабочая станция)
    │   │   ├── windows-ws.pkr.hcl     # Packer конфигурация
    │   │   ├── autounattend.xml       # Файл автоматической установки
    │   │   └── variables.pkr.hcl.example
    │   ├── windows-server/            # Шаблон Windows Server
    │   │   ├── windows-server.pkr.hcl
    │   │   ├── autounattend.xml
    │   │   └── variables.pkr.hcl.example
    │   └── domain-controller/          # Шаблон Domain Controller
    │       ├── domain-controller.pkr.hcl
    │       ├── autounattend.xml
    │       └── variables.pkr.hcl.example
    │
    ├── terraform/                      # 🌍 Terraform конфигурации
    │   ├── windows-10/                # Windows 10 (рабочая станция)
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── terraform.tfvars.example
    │   ├── windows-server/            # Windows Server
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── terraform.tfvars.example
    │   └── domain-controller/        # Domain Controller
    │       ├── main.tf
    │       ├── variables.tf
    │       └── terraform.tfvars.example
    │
    ├── ansible/                        # ⚙️ Ansible конфигурации
    │   ├── inventory.yml              # Инвентарь машин
    │   ├── windows-10/                # Playbook для Windows 10
    │   │   └── playbook.yml
    │   ├── windows-server/            # Playbook для Windows Server
    │   │   └── playbook.yml
    │   ├── domain-controller/         # Playbook для DC
    │   │   └── playbook.yml
    │   └── group_vars/                 # Переменные для групп
    │       └── all/
    │           └── vulnerabilities.yml
    │
    └── scripts/                        # 📜 Скрипты автоматизации
        └── deploy.sh                  # Скрипт развертывания
```

---

## 🖥️ Машины стенда

### 1. Рабочая станция Windows
- **IP:** 192.168.101.10
- **Возможные образы:** Windows XP, Windows 7, Windows 10, Windows 11
- **Packer шаблон:** `infrastructure/packer/windows-10/`
  - `windows-ws.pkr.hcl` - конфигурация Packer
  - `autounattend.xml` - файл автоматической установки
- **Terraform конфигурация:** `infrastructure/terraform/windows-10/`
- **Ansible playbook:** `infrastructure/ansible/windows-10/playbook.yml`

### 2. Windows Server
- **IP:** 192.168.101.20
- **Версии:** Windows Server 2016, 2019, 2022
- **Packer шаблон:** `infrastructure/packer/windows-server/`
  - `windows-server.pkr.hcl` - конфигурация Packer
  - `autounattend.xml` - файл автоматической установки
- **Terraform конфигурация:** `infrastructure/terraform/windows-server/`
- **Ansible playbook:** `infrastructure/ansible/windows-server/playbook.yml`

### 3. Domain Controller
- **IP:** 192.168.101.30
- **Версии:** Windows Server 2016, 2019, 2022 (с ролью AD DS)
- **Packer шаблон:** `infrastructure/packer/domain-controller/`
  - `domain-controller.pkr.hcl` - конфигурация Packer
  - `autounattend.xml` - файл автоматической установки
- **Terraform конфигурация:** `infrastructure/terraform/domain-controller/`
- **Ansible playbook:** `infrastructure/ansible/domain-controller/playbook.yml`

---

## 🌐 Сетевая топология

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

---

## 📊 Статистика проекта

### Packer конфигурации
- **Конфигураций:** 3 (по одной для каждой машины)
- **Файлов:** 9 (3 .pkr.hcl + 3 autounattend.xml + 3 variables.pkr.hcl.example)
- **Строк кода:** ~600

### Terraform конфигурации
- **Файлов:** 9 (3 машины × 3 файла)
- **Строк кода:** ~300

### Ansible playbooks
- **Playbooks:** 3
- **Строк кода:** ~200 (базовые, будут расширены)

### Скрипты
- **Скриптов:** 1
- **Строк кода:** ~100

---

## 🔗 Навигация

### Для студентов
1. Начните с: `docs/learning/STUDENT_GUIDE.md`
2. Изучите уязвимости: `docs/overview/machine-scenarios.md`

### Для преподавателей
1. Начните с: `docs/learning/INSTRUCTOR_GUIDE.md`
2. Разверните инфраструктуру: `docs/deployment/DEPLOYMENT.md`

### Для администраторов

1. **Создание шаблонов через Packer:**
   - `infrastructure/packer/README.md` - документация
   - `infrastructure/packer/QUICKSTART.md` - быстрый старт
   - `infrastructure/packer/*/variables.pkr.hcl` - настройка переменных

2. **Развертывание через Terraform:**
   - `infrastructure/scripts/deploy.sh` - автоматическое развертывание
   - `infrastructure/terraform/*/terraform.tfvars` - настройка переменных

---

**Структура проекта актуальна на момент создания документа.**
