#!/bin/bash

# Интерактивный скрипт для настройки уязвимостей в учебной инфраструктуре
# Позволяет выбрать какие категории уязвимостей будут включены

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Путь к файлу конфигурации
CONFIG_FILE="../ansible/group_vars/all/vulnerabilities.yml"
CONFIG_DIR="../ansible/group_vars/all"

# Массивы для хранения выбора
declare -A UBUNTU_VULNS
declare -A WINDOWS_SERVER_VULNS
declare -A WINDOWS_CLIENT_VULNS

# Функция для отображения заголовка
show_header() {
    clear
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo -e "${BOLD}${BLUE}  Настройка уязвимостей учебной инфраструктуры${NC}"
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo ""
}

# Функция для отображения меню
show_menu() {
    echo -e "${BOLD}Выберите действие:${NC}"
    echo ""
        echo "  1) Настроить уязвимости Ubuntu Server"
        echo "  2) Настроить уязвимости Windows Server 2016"
        echo "  3) Настроить уязвимости Windows 10 Pro"
        echo "  4) Предустановленные профили (Начинающий/Средний/Продвинутый)"
        echo "  5) Просмотр текущей конфигурации"
        echo "  6) Предпросмотр конфигурации"
        echo "  7) Сохранить конфигурацию"
        echo "  8) Выход"
    echo ""
    echo -n -e "${CYAN}Ваш выбор: ${NC}"
}

# Функция для отображения категорий Ubuntu
show_ubuntu_categories() {
    echo -e "${BOLD}${GREEN}Категории уязвимостей Ubuntu Server:${NC}"
    echo ""
    echo "  1)  Аутентификация и управление аккаунтами"
    echo "  2)  Уязвимости SSH"
    echo "  3)  Ошибки конфигурации сети и firewall"
    echo "  4)  Ошибки обновлений и пакетов"
    echo "  5)  Ошибки управления службами"
    echo "  6)  Ошибки прав доступа и файлов"
    echo "  7)  Уязвимости веб-сервисов"
    echo "  8)  Ошибки логирования"
    echo "  9)  Уязвимости контейнеризации"
    echo "  10) Ошибки резервного копирования"
    echo "  11) Ошибки безопасности ядра"
    echo "  12) Физическая безопасность"
    echo ""
    echo "  0)  Вернуться в главное меню"
    echo ""
}

# Функция для отображения категорий Windows Server
show_windows_server_categories() {
    echo -e "${BOLD}${GREEN}Категории уязвимостей Windows Server 2016:${NC}"
    echo ""
    echo "  1)  Аутентификация и управление учётными записями"
    echo "  2)  Ошибки в настройке GPO"
    echo "  3)  Ошибки в управлении правами"
    echo "  4)  Уязвимости конфигурации сети"
    echo "  5)  Ошибки при настройке контроллеров домена"
    echo "  6)  Ошибки обновлений и антивируса"
    echo "  7)  Уязвимости логирования"
    echo "  8)  Ошибки резервного копирования"
    echo "  9)  Ошибки сервисных аккаунтов"
    echo "  10) Устаревшие технологии"
    echo ""
    echo "  0)  Вернуться в главное меню"
    echo ""
}

# Функция для отображения категорий Windows Client
show_windows_client_categories() {
    echo -e "${BOLD}${GREEN}Категории уязвимостей Windows 10 Pro:${NC}"
    echo ""
    echo "  1)  Слабые пароли"
    echo "  2)  UAC отключен"
    echo "  3)  Обновления отключены"
    echo "  4)  Windows Defender отключен"
    echo "  5)  SMBv1 включен"
    echo "  6)  Неправильные права доступа"
    echo "  7)  Брандмауэр отключен"
    echo "  8)  RDP включен"
    echo ""
    echo "  0)  Вернуться в главное меню"
    echo ""
}

# Функция для показа описания категории Ubuntu
show_ubuntu_category_details() {
    local cat=$1
    show_header
    echo -e "${BOLD}${YELLOW}Описание категории $cat${NC}"
    echo ""
    
    case $cat in
        1)
            echo -e "${BOLD}1. ОШИБКИ В УПРАВЛЕНИИ АККАУНТАМИ И АУТЕНТИФИКАЦИЕЙ${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Создание пользователей со слабыми паролями:"
            echo "    - admin/admin123"
            echo "    - user1/password123"
            echo "    - user2/123456"
            echo "    - root/root123"
            echo "  • Отключение PAM-ограничений (minlen = 1)"
            echo "  • Отключение блокировки после неверных попыток"
            echo "  • Пароли никогда не истекают (chage -M -1)"
            echo "  • Широкие sudo права (NOPASSWD для всех)"
            echo "  • Отсутствие MFA"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Легкий брутфорс паролей, компрометация аккаунтов"
            ;;
        2)
            echo -e "${BOLD}2. УЯЗВИМОСТИ ПРИ КОНФИГУРАЦИИ SSH${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • PermitRootLogin yes (разрешен root login)"
            echo "  • PasswordAuthentication yes (парольная аутентификация)"
            echo "  • MaxAuthTries 1000 (неограниченные попытки)"
            echo "  • Слабые алгоритмы (diffie-hellman-group1-sha1, aes128-cbc)"
            echo "  • Отключен fail2ban"
            echo "  • Отключен firewall"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Брутфорс SSH, использование устаревших протоколов"
            ;;
        3)
            echo -e "${BOLD}3. ОШИБКИ КОНФИГУРАЦИИ СЕТИ И FIREWALL${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • UFW полностью отключен"
            echo "  • Открытые небезопасные порты:"
            echo "    - Telnet (23)"
            echo "    - FTP (21)"
            echo "    - Rlogin (513)"
            echo "  • Нет сетевой сегментации"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Несанкционированный доступ, атаки через открытые порты"
            ;;
        6)
            echo -e "${BOLD}6. ОШИБКИ С ПРАВАМИ ДОСТУПА И ФАЙЛАМИ${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Неправильные права на директории:"
            echo "    - /etc с правами 777"
            echo "    - /var с правами 777"
            echo "    - /home с правами 777"
            echo "  • /etc/shadow с неправильными правами"
            echo "  • Небезопасные cron задачи"
            echo "  • 10 подкатегорий уязвимостей /etc/shadow:"
            echo "    1. Неправильные права доступа"
            echo "    2. Утечки через бэкапы"
            echo "    3. Ошибки в конфигурации PAM"
            echo "    4. Уязвимые алгоритмы хеширования"
            echo "    5. Неправильные настройки shadow aging"
            echo "    6. Доступ через SUID-приложения"
            echo "    7. Недостаточная защита от локального пользователя"
            echo "    8. Утечка через web-приложения"
            echo "    9. Смешивание system и application accounts"
            echo "    10. Ошибки при клонировании систем"
            echo ""
            echo -e "${YELLOW}Риски:${NC} КРИТИЧНО - утечка хешей паролей, компрометация системы"
            ;;
        *)
            echo -e "${BOLD}Категория $cat${NC}"
            echo ""
            echo "Подробное описание см. в документации:"
            echo "  ../../docs/overview/machine-scenarios.md"
            ;;
    esac
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Функция для выбора категорий Ubuntu
configure_ubuntu() {
    while true; do
        show_header
        echo -e "${BOLD}${YELLOW}Настройка уязвимостей Ubuntu Server${NC}"
        echo ""
        show_ubuntu_categories
        
        # Показать текущий статус
        echo -e "${CYAN}Текущий статус:${NC}"
        for i in {1..12}; do
            status="${RED}❌${NC}"
            if [ "${UBUNTU_VULNS[$i]}" = "true" ]; then
                status="${GREEN}✅${NC}"
            fi
            echo -e "  Категория $i: $status"
        done
        echo ""
        echo -e "${CYAN}Команды:${NC}"
        echo "  • Введите номер категории (1-12) для включения/отключения"
        echo "  • Введите 'd' + номер для просмотра описания"
        echo "  • Введите 0 для возврата в главное меню"
        echo ""
        
        read -p "Ваш выбор: " choice
        
        if [ "$choice" = "0" ]; then
            break
        elif [[ "$choice" =~ ^d[0-9]+$ ]]; then
            # Показать описание
            cat_num=${choice#d}
            if [ "$cat_num" -ge 1 ] && [ "$cat_num" -le 12 ]; then
                show_ubuntu_category_details "$cat_num"
            fi
        elif [ "$choice" -ge 1 ] && [ "$choice" -le 12 ]; then
            if [ "${UBUNTU_VULNS[$choice]}" = "true" ]; then
                UBUNTU_VULNS[$choice]="false"
                echo -e "${YELLOW}Категория $choice отключена${NC}"
            else
                UBUNTU_VULNS[$choice]="true"
                echo -e "${GREEN}Категория $choice включена${NC}"
            fi
            sleep 1
        else
            echo -e "${RED}Неверный выбор!${NC}"
            sleep 1
        fi
    done
}

# Функция для показа описания категории Windows Server
show_windows_server_category_details() {
    local cat=$1
    show_header
    echo -e "${BOLD}${YELLOW}Описание категории $cat${NC}"
    echo ""
    
    case $cat in
        1)
            echo -e "${BOLD}1. УЯЗВИМОСТИ АУТЕНТИФИКАЦИИ И УПРАВЛЕНИЯ УЧЁТНЫМИ ЗАПИСЯМИ${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Создание пользователей со слабыми паролями:"
            echo "    - Administrator/Admin123!"
            echo "    - admin/admin123"
            echo "    - user1/password123"
            echo "  • Отключение политики сложных паролей"
            echo "  • Нет истории паролей (можно повторять)"
            echo "  • Пароли никогда не истекают"
            echo "  • Использование Domain Admin для обычных задач"
            echo "  • Отсутствие MFA"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Легкий брутфорс, компрометация домена"
            ;;
        2)
            echo -e "${BOLD}2. ОШИБКИ В НАСТРОЙКЕ ПОЛИТИК БЕЗОПАСНОСТИ (GPO)${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • PowerShell Remoting без ограничений (TrustedHosts = *)"
            echo "  • Отключен аудит событий безопасности"
            echo "  • Пароли в GPP (Group Policy Preferences)"
            echo "  • Нет ограничения на неподписанные драйверы"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Удаленное выполнение команд, утечка учетных данных"
            ;;
        4)
            echo -e "${BOLD}4. УЯЗВИМОСТИ ИЗ-ЗА НЕПРАВИЛЬНОЙ КОНФИГУРАЦИИ СЕТИ${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • SMBv1 включен (уязвим к EternalBlue)"
            echo "  • NTLMv1 разрешен (слабый протокол)"
            echo "  • LDAP без TLS"
            echo "  • Широкие правила брандмауэра"
            echo "  • Небезопасная конфигурация DNS"
            echo ""
            echo -e "${YELLOW}Риски:${NC} КРИТИЧНО - использование устаревших протоколов, перехват трафика"
            ;;
        *)
            echo -e "${BOLD}Категория $cat${NC}"
            echo ""
            echo "Подробное описание см. в документации:"
            echo "  ../../docs/overview/machine-scenarios.md"
            ;;
    esac
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Функция для выбора категорий Windows Server
configure_windows_server() {
    while true; do
        show_header
        echo -e "${BOLD}${YELLOW}Настройка уязвимостей Windows Server 2016${NC}"
        echo ""
        show_windows_server_categories
        
        # Показать текущий статус
        echo -e "${CYAN}Текущий статус:${NC}"
        for i in {1..10}; do
            status="${RED}❌${NC}"
            if [ "${WINDOWS_SERVER_VULNS[$i]}" = "true" ]; then
                status="${GREEN}✅${NC}"
            fi
            echo -e "  Категория $i: $status"
        done
        echo ""
        echo -e "${CYAN}Команды:${NC}"
        echo "  • Введите номер категории (1-10) для включения/отключения"
        echo "  • Введите 'd' + номер для просмотра описания"
        echo "  • Введите 0 для возврата в главное меню"
        echo ""
        
        read -p "Ваш выбор: " choice
        
        if [ "$choice" = "0" ]; then
            break
        elif [[ "$choice" =~ ^d[0-9]+$ ]]; then
            # Показать описание
            cat_num=${choice#d}
            if [ "$cat_num" -ge 1 ] && [ "$cat_num" -le 10 ]; then
                show_windows_server_category_details "$cat_num"
            fi
        elif [ "$choice" -ge 1 ] && [ "$choice" -le 10 ]; then
            if [ "${WINDOWS_SERVER_VULNS[$choice]}" = "true" ]; then
                WINDOWS_SERVER_VULNS[$choice]="false"
                echo -e "${YELLOW}Категория $choice отключена${NC}"
            else
                WINDOWS_SERVER_VULNS[$choice]="true"
                echo -e "${GREEN}Категория $choice включена${NC}"
            fi
            sleep 1
        else
            echo -e "${RED}Неверный выбор!${NC}"
            sleep 1
        fi
    done
}

# Функция для показа описания уязвимости Windows Client
show_windows_client_vuln_details() {
    local vuln=$1
    show_header
    echo -e "${BOLD}${YELLOW}Описание уязвимости $vuln${NC}"
    echo ""
    
    case $vuln in
        1)
            echo -e "${BOLD}1. СЛАБЫЕ ПАРОЛИ${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Пользователи со слабыми паролями:"
            echo "    - user/password123"
            echo "    - admin/admin123"
            echo "  • Отключена политика сложных паролей"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Легкий брутфорс паролей"
            ;;
        2)
            echo -e "${BOLD}2. UAC ОТКЛЮЧЕН${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • User Account Control (UAC) полностью отключен"
            echo "  • Приложения запускаются без запроса подтверждения"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Запуск вредоносного ПО без уведомления"
            ;;
        3)
            echo -e "${BOLD}3. ОБНОВЛЕНИЯ ОТКЛЮЧЕНЫ${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Windows Update отключен"
            echo "  • Нет автоматических обновлений безопасности"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Система уязвима к известным эксплойтам"
            ;;
        4)
            echo -e "${BOLD}4. WINDOWS DEFENDER ОТКЛЮЧЕН${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Windows Defender полностью отключен"
            echo "  • Нет защиты от вредоносного ПО"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Нет защиты от вирусов и троянов"
            ;;
        5)
            echo -e "${BOLD}5. SMBv1 ВКЛЮЧЕН${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • SMBv1 включен (устаревший протокол)"
            echo "  • Уязвим к EternalBlue и другим эксплойтам"
            echo ""
            echo -e "${YELLOW}Риски:${NC} КРИТИЧНО - использование уязвимого протокола"
            ;;
        7)
            echo -e "${BOLD}7. БРАНДМАУЭР ОТКЛЮЧЕН${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Windows Firewall полностью отключен"
            echo "  • Все порты открыты"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Несанкционированный доступ из сети"
            ;;
        8)
            echo -e "${BOLD}8. RDP ВКЛЮЧЕН${NC}"
            echo ""
            echo -e "${CYAN}Что будет настроено:${NC}"
            echo "  • Remote Desktop Protocol включен"
            echo "  • Доступ без ограничений"
            echo ""
            echo -e "${YELLOW}Риски:${NC} Брутфорс RDP, удаленный доступ"
            ;;
        *)
            echo -e "${BOLD}Уязвимость $vuln${NC}"
            echo ""
            echo "Подробное описание см. в документации:"
            echo "  ../../docs/overview/machine-scenarios.md"
            ;;
    esac
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Функция для выбора категорий Windows Client
configure_windows_client() {
    while true; do
        show_header
        echo -e "${BOLD}${YELLOW}Настройка уязвимостей Windows 10 Pro${NC}"
        echo ""
        show_windows_client_categories
        
        # Показать текущий статус
        echo -e "${CYAN}Текущий статус:${NC}"
        for i in {1..8}; do
            status="${RED}❌${NC}"
            if [ "${WINDOWS_CLIENT_VULNS[$i]}" = "true" ]; then
                status="${GREEN}✅${NC}"
            fi
            echo -e "  Уязвимость $i: $status"
        done
        echo ""
        echo -e "${CYAN}Команды:${NC}"
        echo "  • Введите номер уязвимости (1-8) для включения/отключения"
        echo "  • Введите 'd' + номер для просмотра описания"
        echo "  • Введите 0 для возврата в главное меню"
        echo ""
        
        read -p "Ваш выбор: " choice
        
        if [ "$choice" = "0" ]; then
            break
        elif [[ "$choice" =~ ^d[0-9]+$ ]]; then
            # Показать описание
            vuln_num=${choice#d}
            if [ "$vuln_num" -ge 1 ] && [ "$vuln_num" -le 8 ]; then
                show_windows_client_vuln_details "$vuln_num"
            fi
        elif [ "$choice" -ge 1 ] && [ "$choice" -le 8 ]; then
            if [ "${WINDOWS_CLIENT_VULNS[$choice]}" = "true" ]; then
                WINDOWS_CLIENT_VULNS[$choice]="false"
                echo -e "${YELLOW}Уязвимость $choice отключена${NC}"
            else
                WINDOWS_CLIENT_VULNS[$choice]="true"
                echo -e "${GREEN}Уязвимость $choice включена${NC}"
            fi
            sleep 1
        else
            echo -e "${RED}Неверный выбор!${NC}"
            sleep 1
        fi
    done
}

# Функция для предустановленных профилей
show_profiles() {
    show_header
    echo -e "${BOLD}${YELLOW}Предустановленные профили${NC}"
    echo ""
    echo "  1) Начинающий (базовые уязвимости)"
    echo "     - Ubuntu: категории 1-4 (Аутентификация, SSH, Сеть, Обновления)"
    echo "     - Windows Server: категории 1-2 (Аутентификация, GPO)"
    echo "     - Windows Client: уязвимости 1-4"
    echo ""
    echo "  2) Средний уровень"
    echo "     - Ubuntu: категории 1-8 (все кроме сложных)"
    echo "     - Windows Server: категории 1-6"
    echo "     - Windows Client: все уязвимости"
    echo ""
    echo "  3) Продвинутый (все уязвимости)"
    echo "     - Ubuntu: все 12 категорий"
    echo "     - Windows Server: все 10 категорий"
    echo "     - Windows Client: все 8 уязвимостей"
    echo ""
    echo "  0) Вернуться в главное меню"
    echo ""
    
    read -p "Выберите профиль (1-3) или 0 для возврата: " profile_choice
    
    case $profile_choice in
        1)
            # Начинающий
            for i in {1..4}; do UBUNTU_VULNS[$i]="true"; done
            for i in {5..12}; do UBUNTU_VULNS[$i]="false"; done
            for i in {1..2}; do WINDOWS_SERVER_VULNS[$i]="true"; done
            for i in {3..10}; do WINDOWS_SERVER_VULNS[$i]="false"; done
            for i in {1..4}; do WINDOWS_CLIENT_VULNS[$i]="true"; done
            for i in {5..8}; do WINDOWS_CLIENT_VULNS[$i]="false"; done
            echo -e "${GREEN}Профиль 'Начинающий' применен!${NC}"
            sleep 2
            ;;
        2)
            # Средний
            for i in {1..8}; do UBUNTU_VULNS[$i]="true"; done
            for i in {9..12}; do UBUNTU_VULNS[$i]="false"; done
            for i in {1..6}; do WINDOWS_SERVER_VULNS[$i]="true"; done
            for i in {7..10}; do WINDOWS_SERVER_VULNS[$i]="false"; done
            for i in {1..8}; do WINDOWS_CLIENT_VULNS[$i]="true"; done
            echo -e "${GREEN}Профиль 'Средний уровень' применен!${NC}"
            sleep 2
            ;;
        3)
            # Продвинутый
            for i in {1..12}; do UBUNTU_VULNS[$i]="true"; done
            for i in {1..10}; do WINDOWS_SERVER_VULNS[$i]="true"; done
            for i in {1..8}; do WINDOWS_CLIENT_VULNS[$i]="true"; done
            echo -e "${GREEN}Профиль 'Продвинутый' применен!${NC}"
            sleep 2
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Неверный выбор!${NC}"
            sleep 1
            ;;
    esac
}

# Функция для просмотра текущей конфигурации
show_configuration() {
    show_header
    echo -e "${BOLD}${YELLOW}Текущая конфигурация уязвимостей${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}Ubuntu Server:${NC}"
    for i in {1..12}; do
        status="${RED}❌ Отключено${NC}"
        if [ "${UBUNTU_VULNS[$i]}" = "true" ]; then
            status="${GREEN}✅ Включено${NC}"
        fi
        echo -e "  Категория $i: $status"
    done
    echo ""
    
    echo -e "${BOLD}${GREEN}Windows Server 2016:${NC}"
    for i in {1..10}; do
        status="${RED}❌ Отключено${NC}"
        if [ "${WINDOWS_SERVER_VULNS[$i]}" = "true" ]; then
            status="${GREEN}✅ Включено${NC}"
        fi
        echo -e "  Категория $i: $status"
    done
    echo ""
    
    echo -e "${BOLD}${GREEN}Windows 10 Pro:${NC}"
    for i in {1..8}; do
        status="${RED}❌ Отключено${NC}"
        if [ "${WINDOWS_CLIENT_VULNS[$i]}" = "true" ]; then
            status="${GREEN}✅ Включено${NC}"
        fi
        echo -e "  Уязвимость $i: $status"
    done
    echo ""
    
    # Подсчет
    ubuntu_count=0
    for i in {1..12}; do
        if [ "${UBUNTU_VULNS[$i]}" = "true" ]; then
            ubuntu_count=$((ubuntu_count + 1))
        fi
    done
    
    windows_server_count=0
    for i in {1..10}; do
        if [ "${WINDOWS_SERVER_VULNS[$i]}" = "true" ]; then
            windows_server_count=$((windows_server_count + 1))
        fi
    done
    
    windows_client_count=0
    for i in {1..8}; do
        if [ "${WINDOWS_CLIENT_VULNS[$i]}" = "true" ]; then
            windows_client_count=$((windows_client_count + 1))
        fi
    done
    
    echo -e "${CYAN}Итого:${NC}"
    echo -e "  Ubuntu Server: $ubuntu_count/12 категорий"
    echo -e "  Windows Server 2016: $windows_server_count/10 категорий"
    echo -e "  Windows 10 Pro: $windows_client_count/8 уязвимостей"
    echo ""
    
    read -p "Нажмите Enter для продолжения..."
}

# Функция для предпросмотра конфигурации
preview_configuration() {
    show_header
    echo -e "${BOLD}${YELLOW}Предпросмотр конфигурации${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}Ubuntu Server - выбранные категории:${NC}"
    for i in {1..12}; do
        if [ "${UBUNTU_VULNS[$i]}" = "true" ]; then
            echo -e "  ${GREEN}✅ Категория $i${NC}"
        fi
    done
    echo ""
    
    echo -e "${BOLD}${GREEN}Windows Server 2016 - выбранные категории:${NC}"
    for i in {1..10}; do
        if [ "${WINDOWS_SERVER_VULNS[$i]}" = "true" ]; then
            echo -e "  ${GREEN}✅ Категория $i${NC}"
        fi
    done
    echo ""
    
    echo -e "${BOLD}${GREEN}Windows 10 Pro - выбранные уязвимости:${NC}"
    for i in {1..8}; do
        if [ "${WINDOWS_CLIENT_VULNS[$i]}" = "true" ]; then
            echo -e "  ${GREEN}✅ Уязвимость $i${NC}"
        fi
    done
    echo ""
    
    # Подсчет
    ubuntu_count=0
    for i in {1..12}; do
        if [ "${UBUNTU_VULNS[$i]}" = "true" ]; then
            ubuntu_count=$((ubuntu_count + 1))
        fi
    done
    
    windows_server_count=0
    for i in {1..10}; do
        if [ "${WINDOWS_SERVER_VULNS[$i]}" = "true" ]; then
            windows_server_count=$((windows_server_count + 1))
        fi
    done
    
    windows_client_count=0
    for i in {1..8}; do
        if [ "${WINDOWS_CLIENT_VULNS[$i]}" = "true" ]; then
            windows_client_count=$((windows_client_count + 1))
        fi
    done
    
    echo -e "${CYAN}Итого будет настроено:${NC}"
    echo -e "  Ubuntu Server: ${GREEN}$ubuntu_count${NC}/12 категорий"
    echo -e "  Windows Server 2016: ${GREEN}$windows_server_count${NC}/10 категорий"
    echo -e "  Windows 10 Pro: ${GREEN}$windows_client_count${NC}/8 уязвимостей"
    echo ""
    
    read -p "Нажмите Enter для продолжения..."
}

# Функция для сохранения конфигурации
save_configuration() {
    show_header
    echo -e "${BOLD}${YELLOW}Сохранение конфигурации${NC}"
    echo ""
    
    # Показать предпросмотр
    preview_configuration
    
    # Подтверждение
    echo -e "${YELLOW}Вы уверены, что хотите сохранить эту конфигурацию? (y/n)${NC}"
    read -p "Ваш выбор: " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}Сохранение отменено.${NC}"
        sleep 1
        return
    fi
    
    # Создать директорию если не существует
    mkdir -p "$CONFIG_DIR"
    
    # Определить уровень сложности
    ubuntu_count=0
    for i in {1..12}; do
        if [ "${UBUNTU_VULNS[$i]}" = "true" ]; then
            ubuntu_count=$((ubuntu_count + 1))
        fi
    done
    
    windows_server_count=0
    for i in {1..10}; do
        if [ "${WINDOWS_SERVER_VULNS[$i]}" = "true" ]; then
            windows_server_count=$((windows_server_count + 1))
        fi
    done
    
    windows_client_count=0
    for i in {1..8}; do
        if [ "${WINDOWS_CLIENT_VULNS[$i]}" = "true" ]; then
            windows_client_count=$((windows_client_count + 1))
        fi
    done
    
    total_count=$((ubuntu_count + windows_server_count + windows_client_count))
    total_max=30
    
    if [ $total_count -eq $total_max ]; then
        difficulty="advanced"
        enable_all="true"
    elif [ $total_count -ge 15 ]; then
        difficulty="intermediate"
        enable_all="false"
    else
        difficulty="beginner"
        enable_all="false"
    fi
    
    # Создать файл конфигурации
    cat > "$CONFIG_FILE" <<EOF
---
# Конфигурация уязвимостей для учебной инфраструктуры
# Сгенерировано автоматически через configure-vulnerabilities.sh
# Дата: $(date)
# Уровень сложности: $difficulty
# Всего категорий: $total_count/$total_max

# ============================================
# UBUNTU SERVER - УЯЗВИМОСТИ LINUX
# ============================================

ubuntu_vulnerabilities:
  # 1. ОШИБКИ В УПРАВЛЕНИИ АККАУНТАМИ И АУТЕНТИФИКАЦИЕЙ
  auth_weak_passwords: ${UBUNTU_VULNS[1]:-false}
  auth_no_pam_restrictions: ${UBUNTU_VULNS[1]:-false}
  auth_no_account_lockout: ${UBUNTU_VULNS[1]:-false}
  auth_no_password_expiry: ${UBUNTU_VULNS[1]:-false}
  auth_wide_sudo_rights: ${UBUNTU_VULNS[1]:-false}
  auth_no_mfa: ${UBUNTU_VULNS[1]:-false}
  
  # 2. УЯЗВИМОСТИ ПРИ КОНФИГУРАЦИИ SSH
  ssh_password_auth: ${UBUNTU_VULNS[2]:-false}
  ssh_root_login: ${UBUNTU_VULNS[2]:-false}
  ssh_weak_algorithms: ${UBUNTU_VULNS[2]:-false}
  ssh_no_fail2ban: ${UBUNTU_VULNS[2]:-false}
  
  # 3. ОШИБКИ КОНФИГУРАЦИИ СЕТИ И FIREWALL
  network_firewall_off: ${UBUNTU_VULNS[3]:-false}
  network_open_ports: ${UBUNTU_VULNS[3]:-false}
  network_no_segmentation: ${UBUNTU_VULNS[3]:-false}
  
  # 4. ОШИБКИ ПРИ НАСТРОЙКЕ ОБНОВЛЕНИЙ И ПАКЕТОВ
  updates_disabled: ${UBUNTU_VULNS[4]:-false}
  updates_untrusted_repos: ${UBUNTU_VULNS[4]:-false}
  updates_no_integrity_check: ${UBUNTU_VULNS[4]:-false}
  
  # 5. ОШИБКИ В УПРАВЛЕНИИ СЛУЖБАМИ И ДЕМОНАМИ
  services_unnecessary_enabled: ${UBUNTU_VULNS[5]:-false}
  services_root_privileges: ${UBUNTU_VULNS[5]:-false}
  
  # 6. ОШИБКИ С ПРАВАМИ ДОСТУПА И ФАЙЛАМИ
  files_wrong_permissions: ${UBUNTU_VULNS[6]:-false}
  files_wide_sudo: ${UBUNTU_VULNS[6]:-false}
  files_unsafe_cron: ${UBUNTU_VULNS[6]:-false}
  files_shadow_vulnerabilities: ${UBUNTU_VULNS[6]:-false}
  
  # 7. УЯЗВИМОСТИ ВЕБ-СЕРВИСОВ И ПРИЛОЖЕНИЙ
  web_directory_listing: ${UBUNTU_VULNS[7]:-false}
  web_server_tokens: ${UBUNTU_VULNS[7]:-false}
  
  # 8. ОШИБКИ В ЛОГИРОВАНИИ И МОНИТОРИНГЕ
  logging_no_centralized: ${UBUNTU_VULNS[8]:-false}
  logging_no_monitoring: ${UBUNTU_VULNS[8]:-false}
  
  # 9. УЯЗВИМОСТИ КОНТЕЙНЕРИЗАЦИИ
  docker_no_protection: ${UBUNTU_VULNS[9]:-false}
  
  # 10. ОШИБКИ РЕЗЕРВНОГО КОПИРОВАНИЯ
  backup_unreliable: ${UBUNTU_VULNS[10]:-false}
  
  # 11. ОШИБКИ БЕЗОПАСНОСТИ ЯДРА И ОС
  kernel_no_hardening: ${UBUNTU_VULNS[11]:-false}
  kernel_outdated: ${UBUNTU_VULNS[11]:-false}
  
  # 12. ФИЗИЧЕСКАЯ БЕЗОПАСНОСТЬ
  physical_no_encryption: ${UBUNTU_VULNS[12]:-false}

# ============================================
# WINDOWS SERVER 2016 - УЯЗВИМОСТИ WINDOWS
# ============================================

windows_server_vulnerabilities:
  # 1. УЯЗВИМОСТИ АУТЕНТИФИКАЦИИ И УПРАВЛЕНИЯ УЧЁТНЫМИ ЗАПИСЯМИ
  auth_weak_passwords: ${WINDOWS_SERVER_VULNS[1]:-false}
  auth_no_password_policy: ${WINDOWS_SERVER_VULNS[1]:-false}
  auth_no_password_history: ${WINDOWS_SERVER_VULNS[1]:-false}
  auth_no_password_expiry: ${WINDOWS_SERVER_VULNS[1]:-false}
  auth_domain_admin_abuse: ${WINDOWS_SERVER_VULNS[1]:-false}
  auth_no_mfa: ${WINDOWS_SERVER_VULNS[1]:-false}
  
  # 2. ОШИБКИ В НАСТРОЙКЕ ПОЛИТИК БЕЗОПАСНОСТИ (GPO)
  gpo_powershell_unrestricted: ${WINDOWS_SERVER_VULNS[2]:-false}
  gpo_audit_disabled: ${WINDOWS_SERVER_VULNS[2]:-false}
  gpo_passwords_in_gpp: ${WINDOWS_SERVER_VULNS[2]:-false}
  gpo_no_driver_signing: ${WINDOWS_SERVER_VULNS[2]:-false}
  
  # 3. ОШИБКИ В УПРАВЛЕНИИ ПРАВАМИ
  rights_wide_ad_permissions: ${WINDOWS_SERVER_VULNS[3]:-false}
  rights_excessive_privileged_groups: ${WINDOWS_SERVER_VULNS[3]:-false}
  rights_unconstrained_delegation: ${WINDOWS_SERVER_VULNS[3]:-false}
  
  # 4. УЯЗВИМОСТИ ИЗ-ЗА НЕПРАВИЛЬНОЙ КОНФИГУРАЦИИ СЕТИ
  network_dns_insecure: ${WINDOWS_SERVER_VULNS[4]:-false}
  network_firewall_wide_rules: ${WINDOWS_SERVER_VULNS[4]:-false}
  network_smbv1_enabled: ${WINDOWS_SERVER_VULNS[4]:-false}
  network_ntlmv1_allowed: ${WINDOWS_SERVER_VULNS[4]:-false}
  network_ldap_no_tls: ${WINDOWS_SERVER_VULNS[4]:-false}
  
  # 5. ОШИБКИ ПРИ НАСТРОЙКЕ КОНТРОЛЛЕРОВ ДОМЕНА
  dc_used_as_regular_server: ${WINDOWS_SERVER_VULNS[5]:-false}
  dc_insecure_replication: ${WINDOWS_SERVER_VULNS[5]:-false}
  dc_no_physical_control: ${WINDOWS_SERVER_VULNS[5]:-false}
  
  # 6. ОШИБКИ В РАБОТЕ С ОБНОВЛЕНИЯМИ И АНТИВИРУСОМ
  updates_no_wsus: ${WINDOWS_SERVER_VULNS[6]:-false}
  antivirus_wrong_config: ${WINDOWS_SERVER_VULNS[6]:-false}
  
  # 7. УЯЗВИМОСТИ ЛОГИРОВАНИЯ, МОНИТОРИНГА И АУДИТА
  logging_minimal: ${WINDOWS_SERVER_VULNS[7]:-false}
  logging_no_anomaly_monitoring: ${WINDOWS_SERVER_VULNS[7]:-false}
  
  # 8. ОШИБКИ В РЕЗЕРВНОМ КОПИРОВАНИИ
  backup_in_domain: ${WINDOWS_SERVER_VULNS[8]:-false}
  backup_no_critical_objects: ${WINDOWS_SERVER_VULNS[8]:-false}
  
  # 9. ОШИБКИ ПРИ РАБОТЕ С СЕРВИСНЫМИ АККАУНТАМИ
  service_accounts_domain_admin: ${WINDOWS_SERVER_VULNS[9]:-false}
  service_accounts_no_rotation: ${WINDOWS_SERVER_VULNS[9]:-false}
  service_accounts_wrong_spn: ${WINDOWS_SERVER_VULNS[9]:-false}
  
  # 10. УСТАРЕВШИЕ И НЕБЕЗОПАСНЫЕ ТЕХНОЛОГИИ
  legacy_ntlm_instead_kerberos: ${WINDOWS_SERVER_VULNS[10]:-false}
  legacy_frs_instead_dfsr: ${WINDOWS_SERVER_VULNS[10]:-false}
  legacy_smb_no_signing: ${WINDOWS_SERVER_VULNS[10]:-false}

# ============================================
# WINDOWS 10 PRO - КЛИЕНТСКИЕ УЯЗВИМОСТИ
# ============================================

windows_client_vulnerabilities:
  auth_weak_passwords: ${WINDOWS_CLIENT_VULNS[1]:-false}
  auth_uac_disabled: ${WINDOWS_CLIENT_VULNS[2]:-false}
  updates_disabled: ${WINDOWS_CLIENT_VULNS[3]:-false}
  antivirus_disabled: ${WINDOWS_CLIENT_VULNS[4]:-false}
  network_smbv1_enabled: ${WINDOWS_CLIENT_VULNS[5]:-false}
  files_wrong_permissions: ${WINDOWS_CLIENT_VULNS[6]:-false}
  network_firewall_disabled: ${WINDOWS_CLIENT_VULNS[7]:-false}
  network_rdp_enabled: ${WINDOWS_CLIENT_VULNS[8]:-false}

# ============================================
# ОБЩИЕ НАСТРОЙКИ
# ============================================

# Включить все уязвимости по умолчанию (для быстрого развертывания)
enable_all_vulnerabilities: $enable_all

# Уровень сложности (beginner, intermediate, advanced)
difficulty_level: "$difficulty"  # beginner, intermediate, advanced
EOF

    echo -e "${GREEN}✓ Конфигурация сохранена в: $CONFIG_FILE${NC}"
    echo ""
    echo -e "${CYAN}Следующие шаги:${NC}"
    echo "  1. Проверьте конфигурацию:"
    echo "     ${BLUE}cat $CONFIG_FILE${NC}"
    echo ""
    echo "  2. Запустите Ansible playbook для настройки уязвимостей:"
    echo "     ${BLUE}cd ../ansible${NC}"
    echo "     ${BLUE}ansible-playbook -i inventory.yml playbook.yml${NC}"
    echo ""
    echo -e "${YELLOW}⚠ ВАЖНО:${NC} После применения playbook будут настроены выбранные уязвимости!"
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Функция для загрузки существующей конфигурации
load_configuration() {
    if [ -f "$CONFIG_FILE" ]; then
        # Парсинг файла (упрощенный)
        # В реальности можно использовать yq или python для парсинга YAML
        echo -e "${YELLOW}Загрузка существующей конфигурации...${NC}"
        # По умолчанию все включено
        for i in {1..12}; do
            UBUNTU_VULNS[$i]="true"
        done
        for i in {1..10}; do
            WINDOWS_SERVER_VULNS[$i]="true"
        done
        for i in {1..8}; do
            WINDOWS_CLIENT_VULNS[$i]="true"
        done
    else
        # По умолчанию все включено
        for i in {1..12}; do
            UBUNTU_VULNS[$i]="true"
        done
        for i in {1..10}; do
            WINDOWS_SERVER_VULNS[$i]="true"
        done
        for i in {1..8}; do
            WINDOWS_CLIENT_VULNS[$i]="true"
        done
    fi
}

# Функция для показа описания уязвимостей
show_vulnerability_details() {
    local category=$1
    local os=$2
    
    show_header
    echo -e "${BOLD}${YELLOW}Описание уязвимостей${NC}"
    echo ""
    
    case $os in
        ubuntu)
            case $category in
                1)
                    echo -e "${BOLD}Категория 1: Ошибки в управлении аккаунтами и аутентификацией${NC}"
                    echo ""
                    echo "Включает:"
                    echo "  • Слабые пароли пользователей (admin/admin123, user1/password123)"
                    echo "  • Отсутствие PAM-ограничений для паролей"
                    echo "  • Нет блокировки после неверных попыток входа"
                    echo "  • Пароли никогда не истекают"
                    echo "  • Широкие sudo права (NOPASSWD для всех)"
                    echo "  • Отсутствие MFA"
                    ;;
                2)
                    echo -e "${BOLD}Категория 2: Уязвимости при конфигурации SSH${NC}"
                    echo ""
                    echo "Включает:"
                    echo "  • Разрешен парольный вход без ограничений"
                    echo "  • Разрешен root login"
                    echo "  • Слабые алгоритмы шифрования"
                    echo "  • Нет fail2ban и firewall защиты"
                    ;;
                3)
                    echo -e "${BOLD}Категория 3: Ошибки конфигурации сети и firewall${NC}"
                    echo ""
                    echo "Включает:"
                    echo "  • UFW полностью отключен"
                    echo "  • Открытые небезопасные порты (Telnet, FTP, Rlogin)"
                    echo "  • Нет сетевой сегментации"
                    ;;
                6)
                    echo -e "${BOLD}Категория 6: Ошибки с правами доступа и файлами${NC}"
                    echo ""
                    echo "Включает:"
                    echo "  • Неправильные права на системные директории (777)"
                    echo "  • Широкие sudo права"
                    echo "  • Небезопасные cron задачи"
                    echo "  • 10 подкатегорий уязвимостей /etc/shadow:"
                    echo "    - Неправильные права доступа"
                    echo "    - Утечки через бэкапы"
                    echo "    - Ошибки в конфигурации PAM"
                    echo "    - Уязвимые алгоритмы хеширования"
                    echo "    - И другие..."
                    ;;
                *)
                    echo -e "${BOLD}Категория $category${NC}"
                    echo "Описание см. в документации: ../../docs/overview/machine-scenarios.md"
                    ;;
            esac
            ;;
        windows-server)
            case $category in
                1)
                    echo -e "${BOLD}Категория 1: Уязвимости аутентификации${NC}"
                    echo ""
                    echo "Включает:"
                    echo "  • Слабые пароли (Admin123!, admin123)"
                    echo "  • Отсутствие политики сложных паролей"
                    echo "  • Пароли никогда не истекают"
                    echo "  • Использование Domain Admin для обычных задач"
                    echo "  • Отсутствие MFA"
                    ;;
                2)
                    echo -e "${BOLD}Категория 2: Ошибки в настройке GPO${NC}"
                    echo ""
                    echo "Включает:"
                    echo "  • PowerShell Remoting без ограничений"
                    echo "  • Отключен аудит событий безопасности"
                    echo "  • Пароли в GPP (Group Policy Preferences)"
                    echo "  • Нет ограничения на неподписанные драйверы"
                    ;;
                *)
                    echo -e "${BOLD}Категория $category${NC}"
                    echo "Описание см. в документации: ../../docs/overview/machine-scenarios.md"
                    ;;
            esac
            ;;
    esac
    
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Главный цикл
main() {
    # Инициализация (все включено по умолчанию)
    load_configuration
    
    while true; do
        show_header
        show_menu
        read choice
        
        case $choice in
            1)
                configure_ubuntu
                ;;
            2)
                configure_windows_server
                ;;
            3)
                configure_windows_client
                ;;
            4)
                show_profiles
                ;;
            5)
                show_configuration
                ;;
            6)
                preview_configuration
                ;;
            7)
                save_configuration
                ;;
            8)
                echo -e "${GREEN}Выход...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Неверный выбор!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Запуск
main

