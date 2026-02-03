# Детали используемых технологий

## Обзор

Данный проект использует современный стек технологий для автоматизации развертывания и управления инфраструктурой киберучений. Основные компоненты: **Proxmox** (или libvirt/KVM), **Terraform**, **Ansible**, и скрипты на **Bash** и **Python**.

---

## 1. Proxmox VE

### Описание

**Proxmox Virtual Environment (VE)** — это платформа виртуализации с открытым исходным кодом, основанная на KVM (Kernel-based Virtual Machine) и LXC (Linux Containers). Proxmox предоставляет веб-интерфейс для управления виртуальными машинами и контейнерами.

### Использование в проекте

В текущей реализации проект использует **libvirt/KVM** напрямую, но архитектура позволяет легко адаптировать конфигурации для работы с Proxmox через Terraform провайдер Proxmox.

#### Преимущества Proxmox для проекта:

1. **Централизованное управление**: Веб-интерфейс для мониторинга всех ВМ
2. **Высокая производительность**: Нативная виртуализация через KVM
3. **Масштабируемость**: Поддержка кластеров для распределения нагрузки
4. **Резервное копирование**: Встроенные инструменты для бэкапов
5. **Сетевая изоляция**: Гибкая настройка виртуальных сетей

#### Интеграция с Terraform:

```hcl
# Пример конфигурации для Proxmox (альтернатива libvirt)
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_vm_qemu" "web_server" {
  name        = "web-server"
  target_node = "proxmox-node-1"
  
  clone = "ubuntu-20.04-template"
  
  cores   = 2
  memory  = 4096
  disk {
    storage = "local-lvm"
    size    = "50G"
  }
  
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  ipconfig0 = "ip=192.168.10.10/24,gw=192.168.10.1"
}
```

#### Настройка Proxmox для проекта:

1. **Установка Proxmox VE**:
   ```bash
   # Скачивание ISO образа Proxmox VE
   # Установка на сервер с поддержкой виртуализации
   ```

2. **Создание шаблонов ВМ**:
   ```bash
   # Создание шаблона Ubuntu 20.04
   # Настройка cloud-init
   # Сохранение как шаблон
   ```

3. **Настройка сети**:
   - Создание виртуальных сетей для DMZ, Internal, Development
   - Настройка VLAN для изоляции
   - Конфигурация брандмауэра

4. **API доступ**:
   ```bash
   # Создание API токена в Proxmox
   # Настройка прав доступа
   # Использование в Terraform
   ```

---

## 2. Terraform

### Описание

**Terraform** — инструмент Infrastructure as Code (IaC) от HashiCorp, позволяющий декларативно описывать и управлять инфраструктурой.

### Использование в проекте

Terraform используется для автоматического создания виртуальных машин, сетей и других ресурсов инфраструктуры.

#### Основные компоненты:

1. **Провайдеры**:
   - `libvirt` — для работы с KVM через libvirt
   - `proxmox` — для работы с Proxmox VE (альтернатива)

2. **Модули**:
   - `terraform/modules/vm/` — модуль создания виртуальных машин
   - `terraform/modules/network/` — модуль создания сетей

3. **Конфигурации сценариев**:
   - `stands/windows-stand/infrastructure/terraform/` — конфигурация для конкретного стенда

#### Пример использования модуля VM:

```hcl
module "web_server" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "web-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 50
  network_name   = module.network_dmz.network_name
  ip_address     = "192.168.10.10"
  gateway        = "192.168.10.1"
  dns_servers    = ["192.168.10.30", "8.8.8.8"]
  hostname       = "web-server"
  domain         = "techservice.local"
  base_image_path = "/var/lib/libvirt/images/ubuntu-20.04.img"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

#### Ключевые возможности:

1. **Идемпотентность**: Повторное применение не создает дубликаты
2. **Планирование изменений**: `terraform plan` показывает что будет изменено
3. **Состояние**: Хранение состояния в файле или удаленном бэкенде
4. **Outputs**: Передача информации между модулями и в Ansible

#### Рабочий процесс:

```bash
# 1. Инициализация
terraform init

# 2. Планирование
terraform plan -var-file="terraform.tfvars"

# 3. Применение
terraform apply -var-file="terraform.tfvars"

# 4. Удаление
terraform destroy -var-file="terraform.tfvars"
```

#### Переменные:

Переменные определяются в `variables.tf` и задаются через:
- `terraform.tfvars` — файл с переменными
- `-var` флаги командной строки
- Переменные окружения `TF_VAR_*`

---

## 3. Ansible

### Описание

**Ansible** — инструмент автоматизации конфигурации и управления приложениями. Использует агентless-архитектуру (не требует установки агентов на целевые системы).

### Использование в проекте

Ansible применяется для настройки операционных систем, установки ПО, создания уязвимостей и конфигурации сервисов на развернутых виртуальных машинах.

#### Основные компоненты:

1. **Плейбуки** (`playbooks/`):
   - Основные сценарии развертывания
   - Специфичные плейбуки для каждого типа сервера

2. **Роли** (`roles/`):
   - `vkr_accounts/` — управление пользователями/группами на Linux/Windows
   - `vkr_vuln_linux/` — включаемые уязвимости для Linux (Debian-family + RHEL-family)
   - `vkr_vuln_windows/` — включаемые уязвимости для Windows

3. **Инвентарь** (`inventory.yml`):
   - Список хостов и групп
   - Переменные для хостов и групп

#### Пример плейбука:

```yaml
---
- name: Применение профиля уязвимостей на Linux сервере
  hosts: linux_server
  become: yes
  tasks:
    - ansible.builtin.import_role:
        name: vkr_vuln_linux
      vars:
        vuln_enabled: "{{ vuln_profiles.linux_server | default([]) }}"
```

#### Пример роли:

```yaml
---
# ansible/roles/vkr_vuln_linux/tasks/main.yml (фрагмент)

- name: Выбрать и применить уязвимости
  ansible.builtin.include_tasks: "{{ item }}"
  loop: "{{ vuln_enabled | default([]) | map('regex_replace', '^(.*)$', 'vulns/\\1.yml') | list }}"
```

#### Ключевые возможности:

1. **Идемпотентность**: Повторный запуск безопасен
2. **Модули**: Готовые модули для типичных задач
3. **Шаблоны**: Использование Jinja2 для динамических конфигураций
4. **Handlers**: Выполнение действий при изменениях
5. **Vault**: Шифрование чувствительных данных

#### Рабочий процесс:

```bash
# 1. Проверка доступности хостов
ansible all -i inventory.yml -m ping

# 2. Запуск плейбука
ansible-playbook -i inventory.yml playbook.yml

# 3. Запуск с vault паролем
ansible-playbook -i inventory.yml playbook.yml --vault-password-file ~/.vault_pass
```

#### Интеграция с Terraform:

Ansible инвентарь может генерироваться автоматически из Terraform outputs:

```bash
# Генерация инвентаря из Terraform outputs
terraform output -json | python3 generate_inventory.py > inventory.yml
```

---

## 4. Bash скрипты

### Описание

**Bash скрипты** используются для автоматизации последовательности операций развертывания и управления инфраструктурой.

### Использование в проекте

#### Основные скрипты:

1. **`stands/*/infrastructure/scripts/deploy.sh`** — автоматическое развертывание инфраструктуры:
   - Проверка зависимостей
   - Инициализация Terraform
   - Развертывание ВМ
   - Генерация Ansible инвентаря
   - Применение конфигураций через Ansible

2. **`terraform destroy`** (в каталоге конкретной ВМ/стенда) — удаление инфраструктуры:
   - Подтверждение операции
   - Удаление через Terraform

#### Пример структуры скрипта:

```bash
#!/bin/bash
# Скрипт для автоматического развертывания

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функции
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка зависимостей
check_requirements() {
    command -v terraform >/dev/null 2>&1 || { 
        print_error "Terraform не установлен"; exit 1; 
    }
    command -v ansible-playbook >/dev/null 2>&1 || { 
        print_error "Ansible не установлен"; exit 1; 
    }
}

# Главная функция
main() {
    check_requirements
    # ... остальная логика
}

main "$@"
```

#### Ключевые возможности:

1. **Обработка ошибок**: `set -e` для остановки при ошибках
2. **Цветной вывод**: Улучшение читаемости
3. **Проверка зависимостей**: Валидация перед выполнением
4. **Интеграция**: Вызов Terraform и Ansible

---

## 5. Python скрипты

### Описание

**Python скрипты** используются для сложной логики обработки данных, генерации конфигураций и интеграции между инструментами.

### Использование в проекте

#### Основные задачи:

1. **Генерация Ansible инвентаря** из Terraform outputs:
   ```python
   import json
   import yaml
   
   # Чтение Terraform outputs
   with open('/tmp/terraform_outputs.json', 'r') as f:
       outputs = json.load(f)
   
   # Создание инвентаря
   inventory = {
       'all': {
           'children': {
               'web_servers': {
                   'hosts': {
                       'web-server': {
                           'ansible_host': outputs['web_server_ip']['value']
                       }
                   }
               }
           }
       }
   }
   
   # Сохранение в YAML
   with open('inventory.yml', 'w') as f:
       yaml.dump(inventory, f)
   ```

2. **Обработка данных**:
   - Парсинг JSON outputs от Terraform
   - Генерация YAML конфигураций
   - Валидация данных

3. **Интеграция инструментов**:
   - Связь Terraform и Ansible
   - Обработка результатов выполнения

#### Пример использования в Bash скрипте:

```bash
# Встроенный Python скрипт в Bash
python3 << EOF
import json
import yaml

with open('/tmp/terraform_outputs.json', 'r') as f:
    outputs = json.load(f)

# ... обработка данных ...

print(yaml.dump(inventory, default_flow_style=False))
EOF
```

#### Зависимости:

```bash
# Установка Python библиотек
pip3 install pyyaml jinja2
```

---

## Интеграция технологий

### Последовательность развертывания:

```
1. Terraform
   ├── Создание сетей
   ├── Создание виртуальных машин
   └── Генерация outputs (IP адреса)

2. Python скрипт
   └── Генерация Ansible инвентаря из Terraform outputs

3. Ansible
   ├── Настройка ОС
   ├── Установка ПО
   ├── Создание уязвимостей
   └── Конфигурация сервисов
```

### Пример полного цикла:

```bash
# 1. Развертывание инфраструктуры
cd infrastructure/terraform
terraform init
terraform apply

# 2. Генерация инвентаря
terraform output -json | python3 generate_inventory.py > ../ansible/inventory.yml

# 3. Применение конфигураций
cd ../ansible
ansible-playbook -i inventory.yml playbook.yml

# 4. Удаление (при необходимости)
cd ../terraform
terraform destroy
```

---

## Рекомендации по использованию

### Terraform:

1. **Версионирование**: Используйте версионирование для провайдеров
2. **Модульность**: Разбивайте на переиспользуемые модули
3. **Переменные**: Используйте переменные вместо хардкода
4. **State**: Храните state в удаленном бэкенде для команды

### Ansible:

1. **Роли**: Используйте роли для переиспользования
2. **Vault**: Храните секреты в Ansible Vault
3. **Идемпотентность**: Обеспечивайте безопасность повторных запусков
4. **Тестирование**: Используйте Molecule для тестирования ролей

### Скрипты:

1. **Обработка ошибок**: Всегда обрабатывайте ошибки
2. **Логирование**: Добавляйте информативный вывод
3. **Валидация**: Проверяйте входные данные
4. **Документация**: Комментируйте сложную логику

---

## Дополнительные ресурсы

- [Документация Terraform](https://www.terraform.io/docs)
- [Документация Ansible](https://docs.ansible.com)
- [Документация Proxmox](https://pve.proxmox.com/pve-docs/)
- [Документация libvirt](https://libvirt.org/docs.html)


