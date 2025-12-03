# Краткое руководство по использованию - [Название сценария]

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
cd scenarios/scenario-[name]

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
# Проверка [Машина 1]
[команда проверки]

# Проверка [Машина 2]
[команда проверки]
```

### 5. Удаление

```bash
./scripts/destroy.sh
```

## Структура проекта

```
scenario-[name]/
├── README.md                    # Описание сценария
├── DEPLOYMENT.md               # Подробное руководство по развертыванию
├── network-topology.md         # Сетевая топология
├── machine-scenarios.md        # Сценарии для каждой машины
├── objectives.md               # Цели обучения
├── infrastructure/
│   ├── terraform/              # Terraform конфигурации
│   └── ansible/                # Ansible конфигурации
└── scripts/
    ├── deploy.sh               # Скрипт развертывания
    └── destroy.sh              # Скрипт удаления
```

## Основные серверы

| Сервер | IP адрес | Роль | Уязвимости |
|--------|----------|------|-----------|
| [server-1] | [IP] | [Роль] | [Уязвимости] |
| [server-2] | [IP] | [Роль] | [Уязвимости] |

## Сетевые сегменты

- **[Сеть 1]** ([IP_RANGE]): [Описание]
- **[Сеть 2]** ([IP_RANGE]): [Описание]
- **[Сеть 3]** ([IP_RANGE]): [Описание]

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

