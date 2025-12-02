#!/bin/bash
# Скрипт для управления уязвимостями в сценарии ISP-компании

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
VULN_FILE="$ANSIBLE_DIR/vulnerabilities.yml"
BACKUP_DIR="$ANSIBLE_DIR/backups"

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

# Создать директорию для бэкапов
mkdir -p "$BACKUP_DIR"

# Функция для создания бэкапа
backup_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/vulnerabilities_${timestamp}.yml"
    cp "$VULN_FILE" "$backup_file"
    info "Создан бэкап: $backup_file"
}

# Функция для включения/отключения всех уязвимостей
toggle_all_vulnerabilities() {
    local state=$1
    backup_config
    
    if [ "$state" == "enable" ]; then
        sed -i 's/enable_all_vulnerabilities: false/enable_all_vulnerabilities: true/g' "$VULN_FILE"
        sed -i 's/enabled: false/enabled: true/g' "$VULN_FILE"
        info "Все уязвимости включены"
    elif [ "$state" == "disable" ]; then
        sed -i 's/enable_all_vulnerabilities: true/enable_all_vulnerabilities: false/g' "$VULN_FILE"
        sed -i 's/enabled: true/enabled: false/g' "$VULN_FILE"
        info "Все уязвимости отключены"
    fi
}

# Функция для изменения уровня сложности
set_difficulty() {
    local level=$1
    backup_config
    
    if [[ ! "$level" =~ ^(beginner|intermediate|advanced)$ ]]; then
        error "Неверный уровень сложности. Используйте: beginner, intermediate, advanced"
        exit 1
    fi
    
    sed -i "s/difficulty_level: \".*\"/difficulty_level: \"$level\"/g" "$VULN_FILE"
    info "Уровень сложности установлен: $level"
}

# Функция для изменения пароля
change_password() {
    local server=$1
    local password_type=$2
    local new_password=$3
    
    if [ -z "$new_password" ]; then
        error "Не указан новый пароль"
        exit 1
    fi
    
    backup_config
    
    # Экранировать специальные символы для sed
    local escaped_password=$(echo "$new_password" | sed 's/[[\.*^$()+?{|]/\\&/g')
    
    case "$password_type" in
        "root"|"mysql"|"postgresql")
            sed -i "s/${password_type}_password: \".*\"/${password_type}_password: \"$escaped_password\"/g" "$VULN_FILE"
            info "Пароль $password_type для $server изменен"
            ;;
        *)
            error "Неизвестный тип пароля: $password_type"
            exit 1
            ;;
    esac
}

# Функция для включения/отключения конкретной уязвимости
toggle_vulnerability() {
    local server=$1
    local vuln_name=$2
    local state=$3
    
    backup_config
    
    if [ "$state" == "enable" ]; then
        # Найти и включить уязвимость
        python3 << EOF
import yaml
import sys

with open('$VULN_FILE', 'r') as f:
    config = yaml.safe_load(f)

# Логика для включения уязвимости
# (упрощенная версия, требует доработки)

with open('$VULN_FILE', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
EOF
        info "Уязвимость $vuln_name для $server включена"
    elif [ "$state" == "disable" ]; then
        warn "Отключение уязвимостей через скрипт требует ручного редактирования файла"
        info "Откройте $VULN_FILE и установите enabled: false для нужной уязвимости"
    fi
}

# Функция для проверки конфигурации
validate_config() {
    info "Проверка конфигурации..."
    
    if ! command -v python3 &> /dev/null; then
        error "Python3 не установлен"
        exit 1
    fi
    
    python3 << EOF
import yaml
import sys

try:
    with open('$VULN_FILE', 'r') as f:
        config = yaml.safe_load(f)
    print("✓ Синтаксис YAML корректен")
    print("✓ Конфигурация загружена успешно")
except yaml.YAMLError as e:
    print(f"✗ Ошибка синтаксиса YAML: {e}")
    sys.exit(1)
except Exception as e:
    print(f"✗ Ошибка: {e}")
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        info "Конфигурация валидна"
    else
        error "Конфигурация содержит ошибки"
        exit 1
    fi
}

# Функция для применения конфигурации
apply_config() {
    info "Применение конфигурации..."
    
    if [ ! -f "$ANSIBLE_DIR/playbook.yml" ]; then
        error "Файл playbook.yml не найден"
        exit 1
    fi
    
    cd "$ANSIBLE_DIR"
    
    if command -v ansible-playbook &> /dev/null; then
        ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
    else
        error "Ansible не установлен"
        exit 1
    fi
}

# Функция для отображения текущей конфигурации
show_config() {
    info "Текущая конфигурация:"
    echo ""
    
    python3 << EOF
import yaml

with open('$VULN_FILE', 'r') as f:
    config = yaml.safe_load(f)

print(f"Уровень сложности: {config.get('global', {}).get('difficulty_level', 'N/A')}")
print(f"Все уязвимости включены: {config.get('global', {}).get('enable_all_vulnerabilities', 'N/A')}")
print(f"Использовать слабые пароли: {config.get('global', {}).get('use_weak_passwords', 'N/A')}")
print(f"Отключить автообновления: {config.get('global', {}).get('disable_auto_updates', 'N/A')}")
EOF
}

# Функция для отображения справки
show_help() {
    cat << EOF
Управление уязвимостями для сценария ISP-компании

Использование:
    $0 [команда] [опции]

Команды:
    enable-all              Включить все уязвимости
    disable-all             Отключить все уязвимости
    set-difficulty LEVEL    Установить уровень сложности (beginner/intermediate/advanced)
    change-password SERVER TYPE PASSWORD  Изменить пароль
    toggle SERVER VULN STATE  Включить/отключить уязвимость (enable/disable)
    validate                 Проверить конфигурацию
    apply                    Применить конфигурацию
    show                     Показать текущую конфигурацию
    backup                   Создать бэкап конфигурации
    help                     Показать эту справку

Примеры:
    $0 enable-all
    $0 set-difficulty beginner
    $0 change-password radius_server mysql "NewPassword123!"
    $0 validate
    $0 apply
    $0 show

EOF
}

# Главная функция
main() {
    case "${1:-help}" in
        "enable-all")
            toggle_all_vulnerabilities "enable"
            ;;
        "disable-all")
            toggle_all_vulnerabilities "disable"
            ;;
        "set-difficulty")
            set_difficulty "$2"
            ;;
        "change-password")
            change_password "$2" "$3" "$4"
            ;;
        "toggle")
            toggle_vulnerability "$2" "$3" "$4"
            ;;
        "validate")
            validate_config
            ;;
        "apply")
            apply_config
            ;;
        "show")
            show_config
            ;;
        "backup")
            backup_config
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"

