# Быстрое тестовое развертывание одной машины

## Подготовка к развертыванию

Перед началом работы убедитесь, что у вас есть:
- Доступ к серверу Proxmox VE
- Права на создание виртуальных машин
- SSH ключ для доступа к создаваемым машинам

## Быстрый старт (3 шага)

### Шаг 1: Подготовка Proxmox

```bash
# 1. Создайте API токен в веб-интерфейсе Proxmox
# Datacenter → Permissions → API Tokens → Add
# Token ID: terraform@pve!terraform-token
# Сохраните Token Secret!

# 2. Создайте шаблон Ubuntu 20.04 в Proxmox:
#    - Загрузите образ Ubuntu 20.04 Cloud Image
#    - Создайте VM из образа
#    - Настройте cloud-init
#    - Преобразуйте в шаблон (правой кнопкой → Convert to Template)
```

### Шаг 2: Настройка Terraform

```bash
# Перейдите в директорию Proxmox
cd scenarios/scenario-isp-company/infrastructure/terraform/proxmox

# Скопируйте пример конфигурации
cp terraform.tfvars.example terraform.tfvars

# Отредактируйте terraform.tfvars
nano terraform.tfvars
```

**Минимальная конфигурация для теста одной машины:**

```hcl
# Настройки Proxmox API
proxmox_api_url          = "https://ВАШ_IP_PROXMOX:8006/api2/json"
proxmox_api_token_id     = "terraform@pve!terraform-token"
proxmox_api_token_secret = "ВАШ_СЕКРЕТ_ТОКЕНА"
proxmox_tls_insecure     = true

# Узел Proxmox
proxmox_target_node = "proxmox"  # Или имя вашего узла

# Шаблон
proxmox_template_name = "ubuntu-20.04-template"

# Хранилище
proxmox_disk_storage = "local-lvm"

# Сеть
network_bridge  = "vmbr0"
network_gateway = "192.168.10.1"
dns_servers     = ["8.8.8.8", "8.8.4.4"]

# SSH
ssh_public_key_file = "~/.ssh/id_rsa.pub"
ssh_user            = "ubuntu"

# ВКЛЮЧИТЬ ТОЛЬКО ОДНУ МАШИНУ ДЛЯ ТЕСТА
enable_radius_server    = true   # ← Включить RADIUS сервер
enable_billing_server   = false
enable_web_server       = false
enable_monitoring_server = false
enable_jump_server      = false
enable_kali_attacker     = false

# Минимальные ресурсы для теста
radius_cpu     = 1
radius_memory  = 2048
radius_disk_size = "20G"
```

### Шаг 3: Развертывание

```bash
# Инициализация Terraform
terraform init

# Просмотр плана (что будет создано)
terraform plan

# Применение (создание машины)
terraform apply
# Введите 'yes' для подтверждения
```

## Варианты развертывания

### Вариант 1: Использование скрипта (рекомендуется)

```bash
cd scenarios/scenario-isp-company/infrastructure/terraform/proxmox
./deploy-single-vm.sh
```

Скрипт предложит выбрать машину из меню и автоматически настроит конфигурацию.

### Вариант 2: Ручная настройка

Отредактируйте `terraform.tfvars` и установите только нужный флаг в `true`:

```hcl
# Для RADIUS сервера:
enable_radius_server = true
enable_billing_server = false
enable_web_server = false
# ... остальные false
```

## Проверка развертывания

### 1. Проверка в Proxmox

В веб-интерфейсе Proxmox:
- **Datacenter → local → VMs**
- Должна появиться созданная ВМ
- Проверьте, что она запущена

### 2. Получение IP адреса

```bash
# Через Terraform
terraform output vm_ips

# Или в веб-интерфейсе Proxmox посмотрите IP адрес ВМ
```

### 3. Подключение к машине

```bash
# Подождите 1-2 минуты после создания (cloud-init)
ssh ubuntu@<IP_ADDRESS>

# Или с указанием ключа:
ssh -i ~/.ssh/id_rsa ubuntu@<IP_ADDRESS>
```

## Рекомендуемая последовательность тестирования

Начните с самых простых машин:

1. **RADIUS сервер** (192.168.10.10) - минимальные ресурсы, простая конфигурация
2. **Jump-сервер** (192.168.30.20) - минимальные ресурсы
3. **Веб-сервер** (192.168.20.20) - для тестирования веб-уязвимостей
4. **Сервер мониторинга** (192.168.30.10) - для тестирования мониторинга
5. **Биллинговый сервер** (192.168.20.10) - требует больше ресурсов
6. **Kali Linux** (192.168.50.10) - требует больше всего ресурсов

## Удаление тестовой машины

```bash
# Удалить конкретную машину
terraform destroy -target=module.radius_server[0]

# Или удалить все
terraform destroy
```

## Минимальные ресурсы для теста

Для тестирования можно использовать минимальные ресурсы:

| Машина | CPU | RAM | Диск |
|--------|-----|-----|------|
| RADIUS сервер | 1 | 2 GB | 20 GB |
| Jump-сервер | 1 | 1 GB | 20 GB |
| Веб-сервер | 1 | 2 GB | 20 GB |
| Мониторинг | 1 | 2 GB | 30 GB |
| Биллинг | 2 | 4 GB | 30 GB |
| Kali Linux | 2 | 4 GB | 50 GB |

## Частые проблемы

### Ошибка: "authentication failed"
- Проверьте правильность токена API
- Убедитесь, что формат токена: `user@realm!token-name`

### Ошибка: "template not found"
- Убедитесь, что шаблон `ubuntu-20.04-template` создан в Proxmox
- Проверьте имя в `proxmox_template_name`

### Ошибка: "insufficient resources"
- Уменьшите CPU, RAM или disk_size в terraform.tfvars
- Проверьте доступные ресурсы в Proxmox

### Не могу подключиться по SSH
- Подождите 2-3 минуты после создания (cloud-init)
- Проверьте, что SSH ключ правильный
- Попробуйте подключиться через консоль в веб-интерфейсе Proxmox

## Полезные команды

```bash
# Просмотр состояния
terraform show

# Просмотр плана изменений
terraform plan

# Просмотр outputs (IP адреса)
terraform output

# Обновление состояния
terraform refresh
```

## Дополнительная информация

Для получения дополнительной информации см.:
- **[Полное руководство по развертыванию](DEPLOYMENT.md)** - подробные инструкции
- **[Быстрый старт](QUICKSTART.md)** - краткое руководство
- **[Обзор сценария](../overview/README.md)** - описание инфраструктуры

---

## Навигация

- **[← Назад к главной](../../README.md)** - главная страница с навигацией
- **[Быстрый старт](QUICKSTART.md)** - краткое руководство по развертыванию
- **[Полное руководство](DEPLOYMENT.md)** - подробные инструкции по развертыванию
- **[Обзор сценария](../overview/README.md)** - описание организации и сети

