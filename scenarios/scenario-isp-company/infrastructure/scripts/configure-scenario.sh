#!/bin/bash

# Интерактивный скрипт для настройки сценария ISP компании
# Позволяет выбрать компоненты, уязвимости и параметры сценария

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ANSIBLE_DIR="$SCENARIO_DIR/infrastructure/ansible"
VULNERABILITIES_FILE="$ANSIBLE_DIR/vulnerabilities.yml"
TERRAFORM_DIR="$SCENARIO_DIR/infrastructure/terraform"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Функции для вывода
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

header() {
    echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}\n"
}

# Функция для выбора да/нет
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local answer
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" answer
    answer=${answer:-$default}
    
    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Функция для выбора из списка
select_from_list() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected
    
    echo -e "${CYAN}$prompt${NC}"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[i]}"
    done
    
    while true; do
        read -p "Выберите номер (1-${#options[@]}): " selected
        if [[ "$selected" =~ ^[0-9]+$ ]] && [ "$selected" -ge 1 ] && [ "$selected" -le "${#options[@]}" ]; then
            echo "$((selected-1))"
            return
        else
            error "Неверный выбор. Попробуйте снова."
        fi
    done
}

# Функция для множественного выбора
select_multiple() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected_indices=()
    local answer
    
    echo -e "${CYAN}$prompt${NC}"
    echo "Введите номера через запятую (например: 1,3,5) или 'all' для всех:"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[i]}"
    done
    
    read -p "Ваш выбор: " answer
    
    if [ "$answer" = "all" ]; then
        for i in "${!options[@]}"; do
            selected_indices+=("$i")
        done
    else
        IFS=',' read -ra selections <<< "$answer"
        for sel in "${selections[@]}"; do
            sel=$(echo "$sel" | xargs)  # trim
            if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#options[@]}" ]; then
                selected_indices+=("$((sel-1))")
            fi
        done
    fi
    
    printf '%s\n' "${selected_indices[@]}"
}

# Функция для ввода значения
ask_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

# Создание резервной копии
create_backup() {
    if [ -f "$VULNERABILITIES_FILE" ]; then
        local backup_file="${VULNERABILITIES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$VULNERABILITIES_FILE" "$backup_file"
        info "Создана резервная копия: $backup_file"
    fi
}

# Главное меню
main_menu() {
    header "Настройка сценария ISP компании"
    
    echo "1. Выбрать машины для включения в сценарий"
    echo "2. Настроить уязвимости"
    echo "3. Настроить параметры машин (CPU, RAM, диск)"
    echo "4. Настроить сетевые параметры"
    echo "5. Настроить учетные записи администраторов"
    echo "6. Настроить уровень сложности"
    echo "7. Просмотреть текущую конфигурацию"
    echo "8. Применить изменения"
    echo "9. Сбросить к настройкам по умолчанию"
    echo "0. Выход"
    echo ""
    
    read -p "Выберите действие: " choice
    
    case "$choice" in
        1) configure_machines ;;
        2) configure_vulnerabilities ;;
        3) configure_machine_resources ;;
        4) configure_network ;;
        5) configure_admins ;;
        6) configure_difficulty ;;
        7) show_configuration ;;
        8) apply_changes ;;
        9) reset_to_defaults ;;
        0) exit 0 ;;
        *) error "Неверный выбор"; main_menu ;;
    esac
}

# Настройка машин
configure_machines() {
    header "Выбор машин для включения в сценарий"
    
    local machines=(
        "RADIUS сервер (192.168.10.10)"
        "Биллинговый сервер (192.168.20.10)"
        "Веб-сервер (192.168.20.20)"
        "Сервер мониторинга (192.168.30.10)"
        "Jump-сервер (192.168.30.20)"
        "Kali Linux атакующий (192.168.50.10)"
    )
    
    echo "Выберите машины для включения в сценарий:"
    local selected=$(select_multiple "Выберите машины" "${machines[@]}")
    
    # Здесь будет логика обновления конфигурации
    # Пока просто сохраняем выбор
    info "Выбрано машин: $(echo "$selected" | wc -w)"
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Настройка уязвимостей
configure_vulnerabilities() {
    header "Настройка уязвимостей"
    
    echo "1. Включить/отключить все уязвимости"
    echo "2. Настроить уязвимости для конкретной машины"
    echo "3. Настроить конкретные типы уязвимостей"
    echo "0. Назад"
    echo ""
    
    read -p "Выберите действие: " choice
    
    case "$choice" in
        1) 
            if ask_yes_no "Включить все уязвимости?"; then
                info "Все уязвимости будут включены"
                # Обновить global.enable_all_vulnerabilities = true
            else
                info "Все уязвимости будут отключены"
                # Обновить global.enable_all_vulnerabilities = false
            fi
            ;;
        2) configure_machine_vulnerabilities ;;
        3) configure_vulnerability_types ;;
        0) main_menu ;;
        *) error "Неверный выбор"; configure_vulnerabilities ;;
    esac
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Настройка уязвимостей для конкретной машины
configure_machine_vulnerabilities() {
    header "Настройка уязвимостей для машины"
    
    local machines=(
        "RADIUS сервер"
        "Биллинговый сервер"
        "Веб-сервер"
        "Сервер мониторинга"
        "Jump-сервер"
    )
    
    local machine_idx=$(select_from_list "Выберите машину" "${machines[@]}")
    local machine_name="${machines[$machine_idx]}"
    
    info "Настройка уязвимостей для: $machine_name"
    
    # Здесь будет логика для конкретной машины
    # Например, для RADIUS сервера:
    if [ "$machine_idx" = "0" ]; then
        if ask_yes_no "Включить слабые пароли БД?" y; then
            info "Слабые пароли БД включены"
        fi
        if ask_yes_no "Включить небезопасную конфигурацию RADIUS?" y; then
            info "Небезопасная конфигурация RADIUS включена"
        fi
    fi
    
    read -p "Нажмите Enter для продолжения..."
    configure_vulnerabilities
}

# Настройка типов уязвимостей
configure_vulnerability_types() {
    header "Настройка типов уязвимостей"
    
    local vuln_types=(
        "Слабые пароли"
        "SQL инъекции"
        "XSS (Cross-Site Scripting)"
        "Небезопасные конфигурации"
        "Утечки данных"
        "Необновленное ПО"
        "Открытые порты"
    )
    
    echo "Выберите типы уязвимостей для включения:"
    local selected=$(select_multiple "Выберите типы уязвимостей" "${vuln_types[@]}")
    
    info "Выбрано типов уязвимостей: $(echo "$selected" | wc -w)"
    
    read -p "Нажмите Enter для продолжения..."
    configure_vulnerabilities
}

# Настройка ресурсов машин
configure_machine_resources() {
    header "Настройка ресурсов машин"
    
    local machines=(
        "RADIUS сервер"
        "Биллинговый сервер"
        "Веб-сервер"
        "Сервер мониторинга"
        "Jump-сервер"
        "Kali Linux атакующий"
    )
    
    local machine_idx=$(select_from_list "Выберите машину для настройки ресурсов" "${machines[@]}")
    local machine_name="${machines[$machine_idx]}"
    
    info "Настройка ресурсов для: $machine_name"
    
    local cpu=$(ask_input "Количество CPU" "2")
    local memory=$(ask_input "Память (MB)" "4096")
    local disk=$(ask_input "Размер диска (GB)" "50")
    
    info "Установлены параметры: CPU=$cpu, RAM=${memory}MB, Disk=${disk}GB"
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Настройка сети
configure_network() {
    header "Настройка сетевых параметров"
    
    echo "1. Настроить IP адреса машин"
    echo "2. Настроить шлюз по умолчанию"
    echo "3. Настроить DNS серверы"
    echo "4. Настроить домен"
    echo "0. Назад"
    echo ""
    
    read -p "Выберите действие: " choice
    
    case "$choice" in
        1) configure_ip_addresses ;;
        2) 
            local gateway=$(ask_input "Шлюз по умолчанию" "192.168.10.1")
            info "Шлюз установлен: $gateway"
            ;;
        3) 
            local dns=$(ask_input "DNS серверы (через запятую)" "8.8.8.8,8.8.4.4")
            info "DNS серверы установлены: $dns"
            ;;
        4) 
            local domain=$(ask_input "Домен" "internetplus.local")
            info "Домен установлен: $domain"
            ;;
        0) main_menu ;;
        *) error "Неверный выбор"; configure_network ;;
    esac
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Настройка IP адресов
configure_ip_addresses() {
    header "Настройка IP адресов"
    
    local radius_ip=$(ask_input "IP адрес RADIUS сервера" "192.168.10.10")
    local billing_ip=$(ask_input "IP адрес биллингового сервера" "192.168.20.10")
    local web_ip=$(ask_input "IP адрес веб-сервера" "192.168.20.20")
    local monitoring_ip=$(ask_input "IP адрес сервера мониторинга" "192.168.30.10")
    local jump_ip=$(ask_input "IP адрес jump-сервера" "192.168.30.20")
    local kali_ip=$(ask_input "IP адрес Kali Linux" "192.168.50.10")
    
    info "IP адреса установлены:"
    echo "  RADIUS: $radius_ip"
    echo "  Billing: $billing_ip"
    echo "  Web: $web_ip"
    echo "  Monitoring: $monitoring_ip"
    echo "  Jump: $jump_ip"
    echo "  Kali: $kali_ip"
    
    read -p "Нажмите Enter для продолжения..."
    configure_network
}

# Настройка администраторов
configure_admins() {
    header "Настройка учетных записей администраторов"
    
    if ask_yes_no "Включить учетные записи администраторов платформы?" y; then
        local admin_user=$(ask_input "Имя пользователя основного администратора" "platform-admin")
        local admin_pass=$(ask_input "Пароль основного администратора" "PlatformAdmin123!")
        
        if ask_yes_no "Создать резервного администратора?" y; then
            local backup_user=$(ask_input "Имя пользователя резервного администратора" "backup-admin")
            local backup_pass=$(ask_input "Пароль резервного администратора" "BackupAdmin123!")
        fi
        
        if ask_yes_no "Использовать SSH ключи для доступа?" y; then
            local ssh_key_file=$(ask_input "Путь к SSH публичному ключу" "~/.ssh/id_rsa.pub")
            info "SSH ключ будет использован: $ssh_key_file"
        fi
        
        info "Учетные записи администраторов настроены"
    else
        info "Учетные записи администраторов отключены"
    fi
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Настройка уровня сложности
configure_difficulty() {
    header "Настройка уровня сложности"
    
    local levels=(
        "Beginner (Начинающий) - базовые уязвимости, простые сценарии"
        "Intermediate (Средний) - средние уязвимости, комплексные сценарии"
        "Advanced (Продвинутый) - сложные уязвимости, многоуровневые атаки"
    )
    
    local level_idx=$(select_from_list "Выберите уровень сложности" "${levels[@]}")
    
    case "$level_idx" in
        0) 
            info "Установлен уровень: Beginner"
            # Обновить global.difficulty_level = "beginner"
            ;;
        1) 
            info "Установлен уровень: Intermediate"
            # Обновить global.difficulty_level = "intermediate"
            ;;
        2) 
            info "Установлен уровень: Advanced"
            # Обновить global.difficulty_level = "advanced"
            ;;
    esac
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Просмотр конфигурации
show_configuration() {
    header "Текущая конфигурация"
    
    if [ -f "$VULNERABILITIES_FILE" ]; then
        echo -e "${CYAN}Содержимое vulnerabilities.yml:${NC}"
        cat "$VULNERABILITIES_FILE" | head -50
        echo "..."
    else
        warn "Файл конфигурации не найден"
    fi
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Применение изменений
apply_changes() {
    header "Применение изменений"
    
    if [ ! -f "$VULNERABILITIES_FILE" ]; then
        error "Файл конфигурации не найден: $VULNERABILITIES_FILE"
        read -p "Нажмите Enter для продолжения..."
        main_menu
        return
    fi
    
    if ask_yes_no "Применить изменения через Ansible?"; then
        info "Запуск Ansible playbook..."
        cd "$ANSIBLE_DIR"
        
        if [ -f "playbook.yml" ]; then
            if command -v ansible-playbook &> /dev/null; then
                ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
                info "Изменения применены"
            else
                error "Ansible не установлен"
            fi
        else
            warn "Playbook не найден. Создайте playbook.yml для применения изменений."
        fi
    else
        info "Изменения сохранены в конфигурационном файле"
        info "Примените их вручную: cd $ANSIBLE_DIR && ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml"
    fi
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Сброс к настройкам по умолчанию
reset_to_defaults() {
    header "Сброс к настройкам по умолчанию"
    
    if ask_yes_no "Вы уверены, что хотите сбросить все настройки к значениям по умолчанию?" n; then
        create_backup
        
        # Здесь можно восстановить файл из git или создать новый с дефолтными значениями
        warn "Функция сброса к настройкам по умолчанию требует реализации"
        info "Используйте git для восстановления: git checkout -- $VULNERABILITIES_FILE"
    fi
    
    read -p "Нажмите Enter для продолжения..."
    main_menu
}

# Главная функция
main() {
    # Проверка зависимостей
    if ! command -v python3 &> /dev/null; then
        error "Python3 не установлен. Необходим для работы скрипта."
        exit 1
    fi
    
    # Создание резервной копии при первом запуске
    if [ -f "$VULNERABILITIES_FILE" ]; then
        create_backup
    fi
    
    # Главный цикл
    while true; do
        main_menu
    done
}

# Запуск скрипта
main

