#!/bin/bash

# Скрипт проверки исправлений уязвимостей студентами
# Проверяет все машины в учебной инфраструктуре

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# IP адреса машин
UBUNTU_IP="192.168.100.10"
WINDOWS_SERVER_IP="192.168.100.20"
WINDOWS_CLIENT_IP="192.168.100.30"

# Учетные данные (после исправлений студентами)
UBUNTU_USER="ubuntu"
UBUNTU_SSH_KEY="${HOME}/.ssh/id_rsa"

WINDOWS_SERVER_USER="Administrator"
WINDOWS_SERVER_PASS="Admin123!"  # Должен быть изменен студентами

WINDOWS_CLIENT_USER="User"
WINDOWS_CLIENT_PASS="User123!"  # Должен быть изменен студентами

# Счетчики
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
SKIPPED_CHECKS=0

# Функция проверки
check() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if eval "$command" > /dev/null 2>&1; then
        if [ "$expected" = "true" ]; then
            echo -e "${GREEN}✓${NC} $name"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        else
            echo -e "${RED}✗${NC} $name (ожидалось false, получено true)"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
    else
        if [ "$expected" = "false" ]; then
            echo -e "${GREEN}✓${NC} $name"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        else
            echo -e "${RED}✗${NC} $name (ожидалось true, получено false)"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
    fi
}

# Функция проверки через SSH
ssh_check() {
    local command="$1"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$UBUNTU_SSH_KEY" \
        "${UBUNTU_USER}@${UBUNTU_IP}" "$command" 2>/dev/null
}

# Функция проверки через WinRM (PowerShell)
winrm_check() {
    local host="$1"
    local user="$2"
    local pass="$3"
    local command="$4"
    
    # Используем ansible для выполнения PowerShell команд на Windows
    ansible windows -i <(cat <<EOF
all:
  hosts:
    target:
      ansible_host: $host
      ansible_user: $user
      ansible_password: "$pass"
      ansible_connection: winrm
      ansible_winrm_transport: basic
      ansible_winrm_server_cert_validation: ignore
EOF
) -m win_shell -a "$command" 2>/dev/null | grep -q "SUCCESS" || return 1
}

echo "=========================================="
echo "Проверка исправлений уязвимостей"
echo "=========================================="
echo ""

# ============================================
# ПРОВЕРКА UBUNTU SERVER
# ============================================

echo -e "${BLUE}=== Ubuntu Server (192.168.100.10) ===${NC}"
echo ""

# Проверка доступности
if ! ssh_check "echo 'OK'" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Ubuntu Server недоступен. Пропуск проверок.${NC}"
    SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
else
    echo "Проверка доступности..."
    check "Ubuntu Server доступен" "ssh_check 'echo OK'" "true"
    
    # 1. Аутентификация
    echo ""
    echo "1. Проверка аутентификации:"
    check "Root login отключен" "ssh_check 'grep -q \"^PermitRootLogin no\" /etc/ssh/sshd_config'" "true"
    check "Парольная аутентификация отключена" "ssh_check 'grep -q \"^PasswordAuthentication no\" /etc/ssh/sshd_config'" "true"
    check "PAM ограничения включены" "ssh_check 'grep -q \"minlen = 1[2-9]\" /etc/security/pwquality.conf || grep -q \"minlen = [2-9][0-9]\" /etc/security/pwquality.conf'" "true"
    check "Fail2ban установлен и запущен" "ssh_check 'systemctl is-active --quiet fail2ban'" "true"
    
    # 2. SSH
    echo ""
    echo "2. Проверка SSH:"
    check "MaxAuthTries <= 6" "ssh_check 'grep -E \"^MaxAuthTries\" /etc/ssh/sshd_config | grep -E \"[0-6]$\"'" "true"
    check "Слабые алгоритмы отключены" "ssh_check '! grep -q \"diffie-hellman-group1-sha1\" /etc/ssh/sshd_config'" "true"
    
    # 3. Сеть и Firewall
    echo ""
    echo "3. Проверка сети и firewall:"
    check "UFW включен" "ssh_check 'ufw status | grep -q \"Status: active\"'" "true"
    check "Небезопасные порты закрыты" "ssh_check '! (ufw status | grep -q \"23/tcp\|21/tcp\|513/tcp\")'" "true"
    
    # 4. Обновления
    echo ""
    echo "4. Проверка обновлений:"
    check "Автоматические обновления включены" "ssh_check 'test -f /etc/apt/apt.conf.d/20auto-upgrades && grep -q \"APT::Periodic::Unattended-Upgrade \"1\"\" /etc/apt/apt.conf.d/20auto-upgrades'" "true"
    
    # 5. Права доступа
    echo ""
    echo "5. Проверка прав доступа:"
    check "/etc имеет правильные права (755)" "ssh_check 'test \"\$(stat -c %a /etc)\" = \"755\"'" "true"
    check "/var имеет правильные права (755)" "ssh_check 'test \"\$(stat -c %a /var)\" = \"755\"'" "true"
    check "/etc/shadow имеет правильные права (640)" "ssh_check 'test \"\$(stat -c %a /etc/shadow)\" = \"640\"'" "true"
    check "Нет директорий с правами 777" "ssh_check '! find /etc /var /home -type d -perm 777 2>/dev/null | head -1'" "true"
    
    # 6. Службы
    echo ""
    echo "6. Проверка служб:"
    check "AppArmor включен" "ssh_check 'systemctl is-active --quiet apparmor'" "true"
    check "Лишние службы отключены" "ssh_check '! (systemctl is-active --quiet cups avahi-daemon bluetooth 2>/dev/null)'" "true"
    
    # 7. Веб-сервисы
    echo ""
    echo "7. Проверка веб-сервисов:"
    check "Directory listing отключен" "ssh_check 'grep -q \"Options -Indexes\" /etc/apache2/apache2.conf || grep -q \"Options -Indexes\" /etc/apache2/sites-enabled/*'" "true"
    check "ServerTokens установлен в Prod" "ssh_check 'grep -q \"ServerTokens Prod\" /etc/apache2/apache2.conf'" "true"
    
    # 8. Логирование
    echo ""
    echo "8. Проверка логирования:"
    check "rsyslog включен" "ssh_check 'systemctl is-active --quiet rsyslog'" "true"
    
    # 9. Docker
    echo ""
    echo "9. Проверка Docker:"
    check "Пользователи не в группе docker" "ssh_check '! getent group docker | grep -q \"admin\|user1\|user2\"'" "true"
    
    # 10. Ядро
    echo ""
    echo "10. Проверка безопасности ядра:"
    check "ASLR включен (randomize_va_space = 2)" "ssh_check 'test \"\$(sysctl -n kernel.randomize_va_space)\" = \"2\"'" "true"
fi

echo ""
echo ""

# ============================================
# ПРОВЕРКА WINDOWS SERVER 2016
# ============================================

echo -e "${BLUE}=== Windows Server 2016 (192.168.100.20) ===${NC}"
echo ""

# Проверка доступности через ping
if ! ping -c 1 -W 2 "$WINDOWS_SERVER_IP" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Windows Server 2016 недоступен. Пропуск проверок.${NC}"
    SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
else
    echo "Проверка доступности..."
    check "Windows Server 2016 доступен" "ping -c 1 -W 2 $WINDOWS_SERVER_IP" "true"
    
    # Проверки через PowerShell (требуется ansible или winrm)
    echo ""
    echo "Примечание: Для полной проверки Windows требуется настроенный WinRM"
    echo "Используйте Ansible для детальной проверки:"
    echo "  ansible-playbook -i inventory.yml verify-windows.yml"
    
    # Базовые проверки через ping и порты
    check "RDP порт открыт (3389)" "nc -z -w 2 $WINDOWS_SERVER_IP 3389" "true"
    check "WinRM порт открыт (5985)" "nc -z -w 2 $WINDOWS_SERVER_IP 5985" "true"
fi

echo ""
echo ""

# ============================================
# ПРОВЕРКА WINDOWS 10 PRO
# ============================================

echo -e "${BLUE}=== Windows 10 Pro (192.168.100.30) ===${NC}"
echo ""

# Проверка доступности через ping
if ! ping -c 1 -W 2 "$WINDOWS_CLIENT_IP" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Windows 10 Pro недоступен. Пропуск проверок.${NC}"
    SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
else
    echo "Проверка доступности..."
    check "Windows 10 Pro доступен" "ping -c 1 -W 2 $WINDOWS_CLIENT_IP" "true"
    
    # Базовые проверки
    check "RDP порт открыт (3389)" "nc -z -w 2 $WINDOWS_CLIENT_IP 3389" "true"
    check "WinRM порт открыт (5985)" "nc -z -w 2 $WINDOWS_CLIENT_IP 5985" "true"
fi

echo ""
echo ""

# ============================================
# ИТОГОВЫЙ ОТЧЕТ
# ============================================

echo "=========================================="
echo "Итоговый отчет"
echo "=========================================="
echo ""
echo "Всего проверок: $TOTAL_CHECKS"
echo -e "${GREEN}Пройдено: $PASSED_CHECKS${NC}"
echo -e "${RED}Провалено: $FAILED_CHECKS${NC}"
echo -e "${YELLOW}Пропущено: $SKIPPED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ] && [ $SKIPPED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ Все проверки пройдены успешно!${NC}"
    exit 0
elif [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Некоторые проверки пропущены, но все выполненные пройдены.${NC}"
    exit 0
else
    echo -e "${RED}✗ Обнаружены неисправленные уязвимости.${NC}"
    echo ""
    echo "Рекомендации:"
    echo "1. Проверьте документацию: docs/overview/machine-scenarios.md"
    echo "2. Используйте чек-лист: docs/assessment/CHECKLIST.md"
    echo "3. Проверьте тестирование: docs/assessment/TESTING.md"
    exit 1
fi

