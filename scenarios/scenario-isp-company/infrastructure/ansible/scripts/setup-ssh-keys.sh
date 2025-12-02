#!/bin/bash

# Скрипт для настройки SSH ключей для администраторов платформы
# Генерирует ключи и настраивает доступ ко всем машинам

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYS_DIR="$ANSIBLE_DIR/keys"
VULNERABILITIES_FILE="$ANSIBLE_DIR/vulnerabilities.yml"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия необходимых инструментов
check_dependencies() {
    info "Проверка зависимостей..."
    
    if ! command -v ssh-keygen &> /dev/null; then
        error "ssh-keygen не найден. Установите openssh-client."
        exit 1
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        error "ansible-playbook не найден. Установите Ansible."
        exit 1
    fi
    
    info "Все зависимости установлены."
}

# Создание директории для ключей
create_keys_directory() {
    if [ ! -d "$KEYS_DIR" ]; then
        info "Создание директории для ключей: $KEYS_DIR"
        mkdir -p "$KEYS_DIR"
        chmod 700 "$KEYS_DIR"
    fi
}

# Генерация SSH ключей
generate_keys() {
    info "Генерация SSH ключей для администраторов платформы..."
    
    # Ключ для основного администратора
    if [ ! -f "$KEYS_DIR/platform_admin_key" ]; then
        info "Генерация ключа для platform-admin..."
        ssh-keygen -t ed25519 -C "platform-admin@internetplus.local" \
            -f "$KEYS_DIR/platform_admin_key" -N "" -q
        chmod 600 "$KEYS_DIR/platform_admin_key"
        chmod 644 "$KEYS_DIR/platform_admin_key.pub"
        info "Ключ создан: $KEYS_DIR/platform_admin_key"
    else
        warn "Ключ platform_admin_key уже существует. Пропуск генерации."
    fi
    
    # Ключ для резервного администратора
    if [ ! -f "$KEYS_DIR/backup_admin_key" ]; then
        info "Генерация ключа для backup-admin..."
        ssh-keygen -t ed25519 -C "backup-admin@internetplus.local" \
            -f "$KEYS_DIR/backup_admin_key" -N "" -q
        chmod 600 "$KEYS_DIR/backup_admin_key"
        chmod 644 "$KEYS_DIR/backup_admin_key.pub"
        info "Ключ создан: $KEYS_DIR/backup_admin_key"
    else
        warn "Ключ backup_admin_key уже существует. Пропуск генерации."
    fi
}

# Обновление vulnerabilities.yml с путями к ключам
update_vulnerabilities_yml() {
    info "Обновление vulnerabilities.yml с путями к SSH ключам..."
    
    # Чтение публичных ключей
    PLATFORM_KEY=$(cat "$KEYS_DIR/platform_admin_key.pub")
    BACKUP_KEY=$(cat "$KEYS_DIR/backup_admin_key.pub")
    
    # Создание временного файла с обновленными ключами
    python3 << EOF
import yaml
import sys

# Чтение файла
with open('$VULNERABILITIES_FILE', 'r', encoding='utf-8') as f:
    config = yaml.safe_load(f)

# Обновление ключей
if 'platform_admins' in config:
    if 'primary_admin' in config['platform_admins']:
        config['platform_admins']['primary_admin']['ssh_key_file'] = 'keys/platform_admin_key.pub'
        # Также можно добавить прямой ключ
        # config['platform_admins']['primary_admin']['ssh_key'] = '$PLATFORM_KEY'
    
    if 'backup_admin' in config['platform_admins']:
        config['platform_admins']['backup_admin']['ssh_key_file'] = 'keys/backup_admin_key.pub'
        # config['platform_admins']['backup_admin']['ssh_key'] = '$BACKUP_KEY'

# Запись обратно
with open('$VULNERABILITIES_FILE', 'w', encoding='utf-8') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print("Файл vulnerabilities.yml обновлен")
EOF

    if [ $? -eq 0 ]; then
        info "Файл vulnerabilities.yml успешно обновлен."
    else
        error "Не удалось обновить vulnerabilities.yml. Убедитесь, что установлен Python3 и PyYAML."
        warn "Вы можете вручную добавить пути к ключам в vulnerabilities.yml:"
        echo "  primary_admin:"
        echo "    ssh_key_file: \"keys/platform_admin_key.pub\""
        echo "  backup_admin:"
        echo "    ssh_key_file: \"keys/backup_admin_key.pub\""
    fi
}

# Применение ключей через Ansible
apply_keys_with_ansible() {
    info "Применение SSH ключей через Ansible..."
    
    cd "$ANSIBLE_DIR"
    
    if [ -f "playbook.yml" ]; then
        info "Запуск Ansible playbook..."
        ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml \
            --tags platform-admin || warn "Ansible playbook завершился с ошибками. Проверьте конфигурацию."
    else
        warn "Файл playbook.yml не найден. Примените ключи вручную или создайте playbook."
    fi
}

# Копирование ключей на машины (альтернативный метод)
copy_keys_manually() {
    info "Инструкции для ручного копирования ключей:"
    echo ""
    echo "Для platform-admin:"
    echo "  ssh-copy-id -i $KEYS_DIR/platform_admin_key.pub platform-admin@192.168.10.10  # RADIUS"
    echo "  ssh-copy-id -i $KEYS_DIR/platform_admin_key.pub platform-admin@192.168.20.10  # Billing"
    echo "  ssh-copy-id -i $KEYS_DIR/platform_admin_key.pub platform-admin@192.168.20.20  # Web"
    echo "  ssh-copy-id -i $KEYS_DIR/platform_admin_key.pub platform-admin@192.168.30.10  # Monitoring"
    echo "  ssh-copy-id -i $KEYS_DIR/platform_admin_key.pub platform-admin@192.168.30.20  # Jump"
    echo ""
    echo "Для backup-admin (на серверах мониторинга и jump):"
    echo "  ssh-copy-id -i $KEYS_DIR/backup_admin_key.pub backup-admin@192.168.30.10  # Monitoring"
    echo "  ssh-copy-id -i $KEYS_DIR/backup_admin_key.pub backup-admin@192.168.30.20  # Jump"
    echo ""
}

# Создание SSH config файла
create_ssh_config() {
    info "Создание примера SSH config файла..."
    
    SSH_CONFIG_EXAMPLE="$KEYS_DIR/ssh_config.example"
    
    cat > "$SSH_CONFIG_EXAMPLE" << 'EOF'
# Пример конфигурации SSH для ~/.ssh/config
# Скопируйте нужные секции в ваш ~/.ssh/config

Host radius-server
    HostName 192.168.10.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host billing-server
    HostName 192.168.20.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host web-server
    HostName 192.168.20.20
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host monitoring-server
    HostName 192.168.30.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host jump-server
    HostName 192.168.30.20
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes
EOF

    info "Пример SSH config создан: $SSH_CONFIG_EXAMPLE"
    info "Скопируйте ключи в ~/.ssh/ и добавьте конфигурацию в ~/.ssh/config"
}

# Вывод информации о ключах
show_key_info() {
    info "Информация о созданных ключах:"
    echo ""
    echo "Приватные ключи (храните в безопасности!):"
    echo "  - $KEYS_DIR/platform_admin_key"
    echo "  - $KEYS_DIR/backup_admin_key"
    echo ""
    echo "Публичные ключи (будут добавлены на серверы):"
    echo "  - $KEYS_DIR/platform_admin_key.pub"
    echo "  - $KEYS_DIR/backup_admin_key.pub"
    echo ""
    echo "Для использования ключей:"
    echo "  1. Скопируйте приватные ключи в ~/.ssh/"
    echo "  2. Установите правильные права: chmod 600 ~/.ssh/*_key"
    echo "  3. Добавьте конфигурацию из $KEYS_DIR/ssh_config.example в ~/.ssh/config"
    echo ""
}

# Главная функция
main() {
    info "Настройка SSH ключей для администраторов платформы"
    echo ""
    
    check_dependencies
    create_keys_directory
    generate_keys
    update_vulnerabilities_yml
    create_ssh_config
    show_key_info
    
    echo ""
    read -p "Применить ключи через Ansible? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_keys_with_ansible
    else
        copy_keys_manually
    fi
    
    info "Настройка SSH ключей завершена!"
}

# Обработка аргументов командной строки
case "${1:-}" in
    generate)
        check_dependencies
        create_keys_directory
        generate_keys
        ;;
    update-config)
        update_vulnerabilities_yml
        ;;
    apply)
        apply_keys_with_ansible
        ;;
    info)
        show_key_info
        ;;
    *)
        main
        ;;
esac

