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
radtest testuser testpass 192.168.10.10 0 testing123

# Проверка веб-сервера
curl http://192.168.20.20

# Проверка биллинга
curl http://192.168.20.10

# Проверка сервера мониторинга
curl http://192.168.30.10

# Проверка jump-сервера
ssh admin@192.168.30.20
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

Сценарий упрощен и содержит **4 ключевых машины инфраструктуры** (плюс машина атакующего):

| Сервер | IP адрес | Роль | Уязвимости |
|--------|----------|------|-----------|
| radius-server | 192.168.10.10 | RADIUS сервер | Слабый пароль БД, небезопасная конфигурация, утечка данных |
| services-server | 192.168.20.10 | Биллинг + Веб (объединенный) | SQL инъекции, слабые пароли БД, уязвимый WordPress, XSS, утечка данных |
| management-server | 192.168.30.10 | Мониторинг + Jump (объединенный) | Слабые SNMP, открытый Zabbix, доступ по паролю SSH, отсутствие 2FA |
| admin-workstation | 192.168.30.20 | Рабочая станция администратора | Слабые пароли, открытые SMB папки, отсутствие антивируса |

**Машина атакующего**:
| Сервер | IP адрес | Роль | Описание |
|--------|----------|------|----------|
| kali-attacker | 192.168.50.10 | Машина атакующего | Kali Linux с предустановленными инструментами для пентеста |

## Сетевые сегменты

- **Инфраструктурная сеть** (192.168.10.0/24): Критичные сервисы (RADIUS)
- **Сервисная сеть** (192.168.20.0/24): Публичные сервисы (Биллинг, Веб)
- **Управляющая сеть** (192.168.30.0/24): Управление инфраструктурой (Сервер управления, Admin Workstation)
- **Сеть атакующего** (192.168.50.0/24): Машина для пентеста (Kali Linux)

## Следующие шаги

1. Изучите документацию в `DEPLOYMENT.md`
2. Разверните инфраструктуру
3. Изучите сценарии в `machine-scenarios.md`
4. Начните практические упражнения из `objectives.md`

## Поддержка

При возникновении проблем см. раздел "Устранение проблем" в [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Навигация

- **[← Назад к главной](../../README.md)** - главная страница с навигацией
- **[Обзор сценария](../overview/README.md)** - описание организации и сети
- **[Тестовое развертывание](QUICK_TEST_DEPLOY.md)** - развертывание одной машины
- **[Полное руководство](DEPLOYMENT.md)** - подробные инструкции по развертыванию


