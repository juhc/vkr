#!/bin/bash

# Скрипт для автоматической проверки исправлений уязвимостей
# Использование: ./verify-fixes.sh [OPTIONS]
#
# Опции:
#   -h, --help              Показать справку
#   -v, --verbose           Подробный вывод
#   -q, --quiet             Только результаты
#   -m, --machine MACHINE   Проверить только указанную машину
#   -o, --output FILE       Сохранить результаты в файл
#
# Примеры:
#   ./verify-fixes.sh                    # Проверить все машины
#   ./verify-fixes.sh -m radius-server   # Проверить только RADIUS сервер
#   ./verify-fixes.sh -o results.txt    # Сохранить результаты в файл

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
VERBOSE=false
QUIET=false
MACHINE=""
OUTPUT_FILE=""
SSH_USER="${SSH_USER:-ubuntu}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_rsa}"

# IP адреса машин
declare -A MACHINES=(
    ["radius-server"]="192.168.10.10"
    ["services-server"]="192.168.20.10"
    ["management-server"]="192.168.30.10"
    ["admin-workstation"]="192.168.30.20"
)

# Счетчики
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Функции

print_help() {
    cat << EOF
Скрипт для автоматической проверки исправлений уязвимостей

Использование: $0 [OPTIONS]

Опции:
    -h, --help              Показать эту справку
    -v, --verbose           Подробный вывод
    -q, --quiet             Только результаты (минимальный вывод)
    -m, --machine MACHINE   Проверить только указанную машину
    -o, --output FILE       Сохранить результаты в файл
    -u, --user USER         Пользователь SSH (по умолчанию: ubuntu)
    -k, --key KEY           Путь к SSH ключу (по умолчанию: ~/.ssh/id_rsa)

Примеры:
    $0                                    # Проверить все машины
    $0 -m radius-server                   # Проверить только RADIUS сервер
    $0 -m services-server                 # Проверить только сервер сервисов
    $0 -o results.txt                     # Сохранить результаты в файл
    $0 -v -m services-server              # Подробная проверка сервера сервисов

Доступные машины:
    - radius-server (192.168.10.10)
    - services-server (192.168.20.10)
    - management-server (192.168.30.10)
    - admin-workstation (192.168.30.20)
EOF
}

log() {
    if [ "$QUIET" = false ]; then
        echo -e "$@"
    fi
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $@"
    fi
}

check_result() {
    local check_name="$1"
    local result="$2"
    local details="${3:-}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        log "${GREEN}✓${NC} $check_name"
        if [ -n "$details" ] && [ "$VERBOSE" = true ]; then
            log_verbose "  $details"
        fi
        return 0
    else
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        log "${RED}✗${NC} $check_name"
        if [ -n "$details" ]; then
            log "${RED}  →${NC} $details"
        fi
        return 1
    fi
}

ssh_exec() {
    local host="$1"
    local command="$2"
    local ip="${MACHINES[$host]}"
    
    if [ -z "$ip" ]; then
        log "${RED}Ошибка: неизвестная машина '$host'${NC}"
        return 1
    fi
    
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        "${SSH_USER}@${ip}" "$command" 2>/dev/null || return 1
}

check_ssh_connection() {
    local host="$1"
    local ip="${MACHINES[$host]}"
    
    log_verbose "Проверка SSH подключения к $host ($ip)..."
    
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        -o BatchMode=yes "${SSH_USER}@${ip}" "echo 'OK'" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Проверки для RADIUS сервера
check_radius_server() {
    local host="radius-server"
    local ip="${MACHINES[$host]}"
    
    log "\n${BLUE}=== Проверка RADIUS сервера ($ip) ===${NC}"
    
    # Проверка SSH подключения
    if ! check_ssh_connection "$host"; then
        check_result "SSH подключение" "FAIL" "Не удается подключиться к $host"
        return 1
    fi
    check_result "SSH подключение" "PASS"
    
    # Проверка пароля MySQL
    log_verbose "Проверка пароля MySQL..."
    if ssh_exec "$host" "mysql -h localhost -u radius -p'radius123' -e 'SELECT 1' 2>/dev/null" >/dev/null 2>&1; then
        check_result "Пароль MySQL изменен" "FAIL" "Слабый пароль 'radius123' все еще работает"
    else
        check_result "Пароль MySQL изменен" "PASS" "Слабый пароль не работает"
    fi
    
    # Проверка доступа MySQL только с localhost
    log_verbose "Проверка доступа MySQL..."
    if ssh_exec "$host" "grep -q 'bind-address.*127.0.0.1' /etc/mysql/mysql.conf.d/mysqld.cnf 2>/dev/null" >/dev/null 2>&1; then
        check_result "MySQL доступ только с localhost" "PASS"
    else
        check_result "MySQL доступ только с localhost" "FAIL" "MySQL доступен извне"
    fi
    
    # Проверка rate limiting в FreeRADIUS
    log_verbose "Проверка rate limiting в FreeRADIUS..."
    if ssh_exec "$host" "grep -q 'rate_limit' /etc/freeradius/3.0/sites-available/default 2>/dev/null" >/dev/null 2>&1; then
        check_result "Rate limiting в FreeRADIUS" "PASS"
    else
        check_result "Rate limiting в FreeRADIUS" "FAIL" "Rate limiting не настроен"
    fi
    
    # Проверка обновлений системы
    log_verbose "Проверка обновлений системы..."
    local updates=$(ssh_exec "$host" "apt list --upgradable 2>/dev/null | grep -c upgradable || echo '0'")
    if [ "$updates" -eq "0" ] || [ -z "$updates" ]; then
        check_result "Системные обновления установлены" "PASS"
    else
        check_result "Системные обновления установлены" "FAIL" "Найдено $updates обновлений"
    fi
    
    # Проверка шифрования паролей клиентов
    log_verbose "Проверка шифрования паролей..."
    if ssh_exec "$host" "mysql -h localhost -u radius -p\$(grep password /etc/freeradius/3.0/mods-available/sql 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d ' \"') -e 'SELECT password FROM radcheck LIMIT 1' radius 2>/dev/null | grep -q '^\$' || echo 'plain'" | grep -q "plain"; then
        check_result "Пароли клиентов зашифрованы" "FAIL" "Пароли хранятся в открытом виде"
    else
        check_result "Пароли клиентов зашифрованы" "PASS"
    fi
}

# Проверки для сервера сервисов (объединенный биллинг + веб)
check_services_server() {
    local host="services-server"
    local ip="${MACHINES[$host]}"
    
    log "\n${BLUE}=== Проверка сервера сервисов ($ip) ===${NC}"
    
    # Проверка SSH подключения
    if ! check_ssh_connection "$host"; then
        check_result "SSH подключение" "FAIL" "Не удается подключиться к $host"
        return 1
    fi
    check_result "SSH подключение" "PASS"
    
    # Проверка SQL инъекций в биллинге (попытка эксплуатации)
    log_verbose "Проверка защиты от SQL инъекций в биллинге..."
    local sql_test=$(curl -s "http://${ip}/billing/login.php?user=admin' OR '1'='1&pass=test" 2>/dev/null | grep -i "error\|sql\|mysql" || echo "")
    if [ -n "$sql_test" ]; then
        check_result "Защита от SQL инъекций (биллинг)" "FAIL" "SQL инъекция все еще возможна"
    else
        check_result "Защита от SQL инъекций (биллинг)" "PASS"
    fi
    
    # Проверка пароля PostgreSQL
    log_verbose "Проверка пароля PostgreSQL..."
    if ssh_exec "$host" "PGPASSWORD='postgres123' psql -h localhost -U postgres -d billing -c 'SELECT 1' 2>/dev/null" >/dev/null 2>&1; then
        check_result "Пароль PostgreSQL изменен" "FAIL" "Слабый пароль 'postgres123' все еще работает"
    else
        check_result "Пароль PostgreSQL изменен" "PASS"
    fi
    
    # Проверка prepared statements
    log_verbose "Проверка использования prepared statements..."
    if ssh_exec "$host" "grep -r 'pg_query\|mysql_query' /var/www/html/*.php 2>/dev/null | grep -v 'prepare\|PreparedStatement' || echo 'OK'" | grep -q "OK"; then
        check_result "Использование prepared statements" "PASS"
    else
        check_result "Использование prepared statements" "FAIL" "Найдены небезопасные SQL запросы"
    fi
    
    # Проверка версии WordPress
    log_verbose "Проверка версии WordPress..."
    local wp_version=$(curl -s "http://${ip}/" 2>/dev/null | grep -oP 'wp-version-[0-9.]+' | head -1 | cut -d'-' -f3 || echo "")
    if [ -n "$wp_version" ]; then
        local major_version=$(echo "$wp_version" | cut -d'.' -f1)
        if [ "$major_version" -lt "5" ]; then
            check_result "Версия WordPress обновлена" "FAIL" "Устаревшая версия WordPress: $wp_version"
        else
            check_result "Версия WordPress обновлена" "PASS" "Версия: $wp_version"
        fi
    else
        check_result "Версия WordPress обновлена" "FAIL" "Не удалось определить версию"
    fi
    
    # Проверка защиты от XSS
    log_verbose "Проверка защиты от XSS..."
    local xss_test=$(curl -s "http://${ip}/?s=<script>alert('XSS')</script>" 2>/dev/null | grep -i "<script>" || echo "")
    if [ -n "$xss_test" ]; then
        check_result "Защита от XSS" "FAIL" "XSS уязвимость все еще присутствует"
    else
        check_result "Защита от XSS" "PASS"
    fi
    
    # Проверка конфигурации Apache
    log_verbose "Проверка конфигурации Apache..."
    if ssh_exec "$host" "grep -q 'ServerTokens Prod' /etc/apache2/apache2.conf 2>/dev/null" >/dev/null 2>&1; then
        check_result "Конфигурация Apache безопасна" "PASS"
    else
        check_result "Конфигурация Apache безопасна" "FAIL" "ServerTokens не настроен"
    fi
    
    # Проверка обновлений
    log_verbose "Проверка обновлений системы..."
    local updates=$(ssh_exec "$host" "apt list --upgradable 2>/dev/null | grep -c upgradable || echo '0'")
    if [ "$updates" -eq "0" ] || [ -z "$updates" ]; then
        check_result "Системные обновления установлены" "PASS"
    else
        check_result "Системные обновления установлены" "FAIL" "Найдено $updates обновлений"
    fi
}

# Проверки для сервера управления (объединенный мониторинг + jump)
check_management_server() {
    local host="management-server"
    local ip="${MACHINES[$host]}"
    
    log "\n${BLUE}=== Проверка сервера управления ($ip) ===${NC}"
    
    # Проверка SSH подключения
    if ! check_ssh_connection "$host"; then
        check_result "SSH подключение" "FAIL" "Не удается подключиться к $host"
        return 1
    fi
    check_result "SSH подключение" "PASS"
    
    # Проверка SNMP community strings
    log_verbose "Проверка SNMP community strings..."
    if ssh_exec "$host" "grep -q 'public\|private' /etc/snmp/snmpd.conf 2>/dev/null" >/dev/null 2>&1; then
        check_result "SNMP community strings изменены" "FAIL" "Слабые community strings все еще используются"
    else
        check_result "SNMP community strings изменены" "PASS"
    fi
    
    # Проверка доступа к Zabbix
    log_verbose "Проверка доступа к Zabbix..."
    local zabbix_auth=$(curl -s "http://${ip}/zabbix/index.php" 2>/dev/null | grep -i "login\|authentication" || echo "")
    if [ -n "$zabbix_auth" ]; then
        check_result "Zabbix требует аутентификацию" "PASS"
    else
        check_result "Zabbix требует аутентификацию" "FAIL" "Zabbix доступен без аутентификации"
    fi
    
    # Проверка отключения аутентификации по паролю SSH
    log_verbose "Проверка SSH конфигурации..."
    if ssh_exec "$host" "grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config 2>/dev/null" >/dev/null 2>&1; then
        check_result "SSH аутентификация по паролю отключена" "PASS"
    else
        check_result "SSH аутентификация по паролю отключена" "FAIL" "Аутентификация по паролю все еще включена"
    fi
    
    # Проверка защиты от брутфорса
    log_verbose "Проверка защиты от брутфорса..."
    if ssh_exec "$host" "grep -q 'fail2ban\|denyhosts' /etc/passwd 2>/dev/null || systemctl is-active --quiet fail2ban 2>/dev/null" >/dev/null 2>&1; then
        check_result "Защита от брутфорса настроена" "PASS"
    else
        check_result "Защита от брутфорса настроена" "FAIL" "Fail2ban или аналогичный инструмент не установлен"
    fi
    
    # Проверка обновлений
    log_verbose "Проверка обновлений системы..."
    local updates=$(ssh_exec "$host" "apt list --upgradable 2>/dev/null | grep -c upgradable || echo '0'")
    if [ "$updates" -eq "0" ] || [ -z "$updates" ]; then
        check_result "Системные обновления установлены" "PASS"
    else
        check_result "Системные обновления установлены" "FAIL" "Найдено $updates обновлений"
    fi
}

# Проверки для компьютера администратора
check_admin_workstation() {
    local host="admin-workstation"
    local ip="${MACHINES[$host]}"
    
    log "\n${BLUE}=== Проверка компьютера администратора ($ip) ===${NC}"
    
    # Проверка SSH подключения
    if ! check_ssh_connection "$host"; then
        check_result "SSH подключение" "FAIL" "Не удается подключиться к $host"
        return 1
    fi
    check_result "SSH подключение" "PASS"
    
    # Проверка закрытия SMB папок
    log_verbose "Проверка SMB конфигурации..."
    if ssh_exec "$host" "systemctl is-active --quiet smbd 2>/dev/null && grep -q 'browseable = no\|read only = yes' /etc/samba/smb.conf 2>/dev/null" >/dev/null 2>&1; then
        check_result "SMB папки защищены" "PASS"
    else
        check_result "SMB папки защищены" "FAIL" "SMB папки открыты или не настроены правильно"
    fi
    
    # Проверка установки антивируса
    log_verbose "Проверка антивируса..."
    if ssh_exec "$host" "which clamav || which sophos || systemctl is-active --quiet clamav-daemon 2>/dev/null" >/dev/null 2>&1; then
        check_result "Антивирус установлен" "PASS"
    else
        check_result "Антивирус установлен" "FAIL" "Антивирус не установлен"
    fi
    
    # Проверка обновлений
    log_verbose "Проверка обновлений системы..."
    local updates=$(ssh_exec "$host" "apt list --upgradable 2>/dev/null | grep -c upgradable || echo '0'")
    if [ "$updates" -eq "0" ] || [ -z "$updates" ]; then
        check_result "Системные обновления установлены" "PASS"
    else
        check_result "Системные обновления установлены" "FAIL" "Найдено $updates обновлений"
    fi
}

# Главная функция
main() {
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -m|--machine)
                MACHINE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -u|--user)
                SSH_USER="$2"
                shift 2
                ;;
            -k|--key)
                SSH_KEY="$2"
                shift 2
                ;;
            *)
                log "${RED}Неизвестная опция: $1${NC}"
                print_help
                exit 1
                ;;
        esac
    done
    
    # Проверка SSH ключа
    if [ ! -f "$SSH_KEY" ]; then
        log "${RED}Ошибка: SSH ключ не найден: $SSH_KEY${NC}"
        exit 1
    fi
    
    # Начало проверки
    log "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║  Автоматическая проверка исправлений уязвимостей         ║${NC}"
    log "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    log ""
    
    # Перенаправление вывода в файл, если указано
    if [ -n "$OUTPUT_FILE" ]; then
        exec > >(tee "$OUTPUT_FILE")
        exec 2>&1
    fi
    
    # Выбор машин для проверки
    if [ -n "$MACHINE" ]; then
        if [ -z "${MACHINES[$MACHINE]:-}" ]; then
            log "${RED}Ошибка: неизвестная машина '$MACHINE'${NC}"
            log "Доступные машины: ${!MACHINES[@]}"
            exit 1
        fi
        MACHINES_TO_CHECK=("$MACHINE")
    else
        MACHINES_TO_CHECK=("${!MACHINES[@]}")
    fi
    
    # Выполнение проверок
    for machine in "${MACHINES_TO_CHECK[@]}"; do
        case "$machine" in
            "radius-server")
                check_radius_server
                ;;
            "billing-server")
                check_billing_server
                ;;
            "web-server")
                check_web_server
                ;;
            "monitoring-server")
                check_monitoring_server
                ;;
            "jump-server")
                check_jump_server
                ;;
            "admin-workstation")
                check_admin_workstation
                ;;
        esac
    done
    
    # Итоговая статистика
    log "\n${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║  Итоговая статистика                                      ║${NC}"
    log "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "Всего проверок: $TOTAL_CHECKS"
    log "${GREEN}Успешно: $PASSED_CHECKS${NC}"
    log "${RED}Провалено: $FAILED_CHECKS${NC}"
    
    local percentage=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        percentage=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi
    
    log "Процент успешных проверок: ${percentage}%"
    log ""
    
    # Оценка
    if [ $percentage -ge 90 ]; then
        log "${GREEN}Оценка: Отлично (5)${NC}"
    elif [ $percentage -ge 75 ]; then
        log "${GREEN}Оценка: Хорошо (4)${NC}"
    elif [ $percentage -ge 60 ]; then
        log "${YELLOW}Оценка: Удовлетворительно (3)${NC}"
    else
        log "${RED}Оценка: Неудовлетворительно (2)${NC}"
    fi
    
    # Код возврата
    if [ $FAILED_CHECKS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Запуск скрипта
main "$@"

