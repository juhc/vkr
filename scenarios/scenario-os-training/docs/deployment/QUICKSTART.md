# 🚀 Быстрый старт - Развертывание за 5 минут

> 📚 **Навигация**: См. [../README.md](../README.md) для полной навигации по документации.

Этот файл содержит минимальные шаги для быстрого развертывания инфраструктуры.

## Предварительные требования

- Linux хост с KVM (libvirt)
- Terraform >= 1.0
- Ansible >= 2.9
- Минимум 16 GB RAM
- Минимум 200 GB дискового пространства

## Шаг 1: Установка зависимостей

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils terraform ansible
sudo usermod -aG libvirt $USER
newgrp libvirt
```

## Шаг 2: Подготовка SSH ключа

```bash
# Если ключа нет, создайте его
ssh-keygen -t ed25519 -C "your_email@example.com"

# Проверьте наличие ключа
cat ~/.ssh/id_ed25519.pub
```

## Шаг 3: Автоматическое развертывание

```bash
cd scenarios/scenario-os-training/infrastructure
./scripts/deploy.sh
```

Или вручную:

```bash
# 1. Terraform
cd terraform
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
terraform init
terraform apply

# 2. Ожидание готовности сервера
sleep 60

# 3. Ansible
cd ../ansible
ansible-playbook -i inventory.yml playbook.yml --limit ubuntu-server
```

## Шаг 4: Проверка

```bash
# Проверка доступности
ping -c 3 192.168.100.10

# Проверка SSH
ssh ubuntu@192.168.100.10 "echo 'OK'"

# Проверка Ansible
cd infrastructure/ansible
ansible ubuntu-server -i inventory.yml -m ping
```

## Что дальше?

- **[../assessment/CHECKLIST.md](../assessment/CHECKLIST.md)** - Полная проверка развертывания
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Подробное руководство
- **[../assessment/VALIDATION.md](../assessment/VALIDATION.md)** - Валидация развертывания
- **[../assessment/TESTING.md](../assessment/TESTING.md)** - Тестирование уязвимостей

## Проблемы?

См. раздел "Устранение проблем" в [DEPLOYMENT.md](DEPLOYMENT.md) или [../assessment/CHECKLIST.md](../assessment/CHECKLIST.md)

---

**💡 Совет**: Для полной навигации по документации см. [../README.md](../README.md)
