#!/bin/bash

# Скрипт для развертывания одной виртуальной машины на Proxmox
# Полезно для тестирования с ограниченными ресурсами

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR"
TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

header() {
    echo -e "\n${CYAN}=== $1 ===${NC}\n"
}

# Проверка наличия terraform.tfvars
if [ ! -f "$TFVARS_FILE" ]; then
    error "Файл terraform.tfvars не найден!"
    info "Скопируйте terraform.tfvars.example в terraform.tfvars и заполните его"
    exit 1
fi

# Меню выбора машины
header "Выбор машины для развертывания"

echo "1. RADIUS сервер (192.168.10.10)"
echo "2. Биллинговый сервер (192.168.20.10)"
echo "3. Веб-сервер (192.168.20.20)"
echo "4. Сервер мониторинга (192.168.30.10)"
echo "5. Jump-сервер (192.168.30.20)"
echo "6. Kali Linux атакующий (192.168.50.10)"
echo "0. Выход"
echo ""

read -p "Выберите машину для развертывания: " choice

case "$choice" in
    1)
        VM_NAME="radius-server"
        ENABLE_VAR="enable_radius_server"
        ;;
    2)
        VM_NAME="billing-server"
        ENABLE_VAR="enable_billing_server"
        ;;
    3)
        VM_NAME="web-server"
        ENABLE_VAR="enable_web_server"
        ;;
    4)
        VM_NAME="monitoring-server"
        ENABLE_VAR="enable_monitoring_server"
        ;;
    5)
        VM_NAME="jump-server"
        ENABLE_VAR="enable_jump_server"
        ;;
    6)
        VM_NAME="kali-attacker"
        ENABLE_VAR="enable_kali_attacker"
        ;;
    0)
        info "Выход"
        exit 0
        ;;
    *)
        error "Неверный выбор"
        exit 1
        ;;
esac

header "Настройка для развертывания $VM_NAME"

# Создание временного файла с настройками
TEMP_TFVARS=$(mktemp)

# Копирование существующего terraform.tfvars
cp "$TFVARS_FILE" "$TEMP_TFVARS"

# Отключение всех машин
sed -i.bak 's/^enable_radius_server.*/enable_radius_server = false/' "$TEMP_TFVARS"
sed -i.bak 's/^enable_billing_server.*/enable_billing_server = false/' "$TEMP_TFVARS"
sed -i.bak 's/^enable_web_server.*/enable_web_server = false/' "$TEMP_TFVARS"
sed -i.bak 's/^enable_monitoring_server.*/enable_monitoring_server = false/' "$TEMP_TFVARS"
sed -i.bak 's/^enable_jump_server.*/enable_jump_server = false/' "$TEMP_TFVARS"
sed -i.bak 's/^enable_kali_attacker.*/enable_kali_attacker = false/' "$TEMP_TFVARS"

# Включение выбранной машины
sed -i.bak "s/^$ENABLE_VAR.*/$ENABLE_VAR = true/" "$TEMP_TFVARS"

# Удаление временных файлов
rm -f "$TEMP_TFVARS.bak"

info "Создан временный файл конфигурации для развертывания только $VM_NAME"

# Показ плана
header "План развертывания"

cd "$TERRAFORM_DIR"

# Использование временного файла через -var-file
info "Запуск terraform plan..."

terraform plan -var-file="$TEMP_TFVARS" -out=tfplan

# Подтверждение
echo ""
read -p "Применить изменения? (y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    header "Применение изменений"
    terraform apply -var-file="$TEMP_TFVARS" tfplan
    info "Машина $VM_NAME успешно развернута!"
    
    # Показать IP адрес
    info "IP адрес машины:"
    terraform output -var-file="$TEMP_TFVARS" vm_ips | grep "$VM_NAME" || true
else
    info "Отменено"
fi

# Очистка
rm -f "$TEMP_TFVARS" tfplan

info "Готово!"

