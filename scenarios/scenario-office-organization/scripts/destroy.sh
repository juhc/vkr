#!/bin/bash
# Скрипт для удаления инфраструктуры

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Удаление инфраструктуры через Terraform
destroy_infrastructure() {
    print_info "Удаление инфраструктуры через Terraform..."
    
    cd "$SCRIPT_DIR/infrastructure/terraform"
    
    if [ -f "terraform.tfvars" ]; then
        terraform destroy -var-file="terraform.tfvars" -auto-approve
    else
        terraform destroy -auto-approve
    fi
    
    print_info "Инфраструктура успешно удалена"
}

main() {
    print_warn "ВНИМАНИЕ: Это удалит всю инфраструктуру!"
    read -p "Вы уверены? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Операция отменена"
        exit 0
    fi
    
    destroy_infrastructure
    print_info "Удаление завершено"
}

main "$@"

