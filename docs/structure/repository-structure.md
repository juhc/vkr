# Структура репозитория (актуальная)

Ниже приведена **ориентировочная** структура (без локальных артефактов вроде `terraform.tfstate`, кешей и секретов).  
Ключевой принцип: **стенд = единица поставки**, поэтому точки входа (`deploy.sh`, `terraform/`, `ansible/`) лежат внутри `stands/<stand>/infrastructure/`.

## Дерево каталогов (верхний уровень)

```
vkr/
├── README.md
├── stands/                         # Учебные стенды (точка входа для администратора)
│   ├── README.md
│   ├── PROJECT_STRUCTURE.md
│   ├── linux-stand/
│   │   ├── README.md
│   │   ├── STRUCTURE.md
│   │   └── infrastructure/
│   │       ├── scripts/
│   │       │   └── deploy.sh        # полный деплой стенда (templates → terraform → ansible)
│   │       ├── templates/           # создание Linux cloud-init templates (ps1 + sh)
│   │       ├── terraform/           # Terraform конфигурации ВМ (Proxmox)
│   │       │   ├── linux-server/
│   │       │   └── linux-ws/
│   │       └── ansible/             # Ansible playbooks + group_vars для стенда
│   │           ├── ansible.cfg
│   │           ├── inventory.yml
│   │           ├── group_vars/
│   │           │   └── all/
│   │           │       ├── vulnerabilities.yml
│   │           │       ├── accounts.yml.example
│   │           │       └── ad.yml.example
│   │           ├── linux-server/playbook.yml
│   │           └── linux-ws/playbook.yml
│   └── windows-stand/
│       ├── README.md
│       ├── STRUCTURE.md
│       └── infrastructure/
│           ├── scripts/
│           │   └── deploy.sh
│           ├── packer/              # сборка Windows templates (опционально, если пересобираете шаблоны)
│           ├── terraform/           # Terraform конфигурации ВМ (Windows 10 / Server / DC)
│           │   ├── domain-controller/
│           │   ├── windows-10/
│           │   └── windows-server/
│           └── ansible/             # Ansible playbooks + group_vars (уязвимости/AD/учётки)
│               ├── ansible.cfg
│               ├── inventory.yml
│               ├── group_vars/all/
│               ├── domain-controller/playbook.yml
│               ├── windows-10/playbook.yml
│               └── windows-server/playbook.yml
├── ansible/
│   └── roles/                       # Общие роли Ansible (переиспользуются между стендами)
│       ├── accounts/                # пользователи/группы (Linux+Windows)
│       ├── ad_join/                 # присоединение к AD (опционально по профилю)
│       ├── ad_org/                  # OU/группы/GPO linking+filtering (на DC)
│       ├── vuln_linux/              # уязвимости Linux
│       ├── vuln_windows/            # уязвимости Windows
│       └── vuln_ad/                 # уязвимости AD/GPO (на DC)
├── docs/
│   ├── README.md                    # индекс документации
│   ├── guides/                      # гайды для администратора/преподавателя/студента
│   ├── technical/                   # технические объяснения и материалы
│   └── structure/                   # документы о структуре проекта (включая этот файл)
├── tools/                           # утилиты (генерация/расширение отчёта и т.п.)
│   ├── update_report_docx.py
│   └── expand_report_copy_docx.py
└── terraform/
    └── modules/                     # Terraform modules (отдельный слой/набор модулей)
        ├── vm/
        └── network/
```

## Что редактировать администратору чаще всего

- **Параметры Proxmox/сети/доступа**: `stands/*/infrastructure/terraform/*/terraform.tfvars` (локально, не коммитить)
- **Профили уязвимостей**: `stands/*/infrastructure/ansible/group_vars/all/vulnerabilities.yml`
- **Пользователи/группы**: `stands/*/infrastructure/ansible/group_vars/all/accounts.yml` (по примеру `accounts.yml.example`)
- **AD параметры и domain join**: `stands/*/infrastructure/ansible/group_vars/all/ad.yml` (по примеру `ad.yml.example`)

