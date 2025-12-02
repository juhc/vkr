#!/bin/bash
# Скрипт для автоматического развертывания инфраструктуры офисной организации

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка наличия необходимых инструментов
check_requirements() {
    print_info "Проверка наличия необходимых инструментов..."
    
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform не установлен"; exit 1; }
    command -v ansible-playbook >/dev/null 2>&1 || { print_error "Ansible не установлен"; exit 1; }
    command -v virsh >/dev/null 2>&1 || { print_error "libvirt не установлен"; exit 1; }
    
    print_info "Все необходимые инструменты установлены"
}

# Проверка базового образа
check_base_image() {
    print_info "Проверка наличия базового образа Ubuntu..."
    
    BASE_IMAGE_PATH="${BASE_IMAGE_PATH:-/var/lib/libvirt/images/ubuntu-20.04-server-cloudimg-amd64.img}"
    
    if [ ! -f "$BASE_IMAGE_PATH" ]; then
        print_warn "Базовый образ не найден: $BASE_IMAGE_PATH"
        print_info "Скачивание образа Ubuntu 20.04 Cloud Image..."
        
        mkdir -p "$(dirname "$BASE_IMAGE_PATH")"
        wget -O "$BASE_IMAGE_PATH" \
            https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
        
        print_info "Образ успешно загружен"
    else
        print_info "Базовый образ найден: $BASE_IMAGE_PATH"
    fi
}

# Инициализация Terraform
init_terraform() {
    print_info "Инициализация Terraform..."
    
    cd "$SCRIPT_DIR/infrastructure/terraform"
    terraform init
}

# Развертывание инфраструктуры через Terraform
deploy_infrastructure() {
    print_info "Развертывание инфраструктуры через Terraform..."
    
    cd "$SCRIPT_DIR/infrastructure/terraform"
    
    if [ -f "terraform.tfvars" ]; then
        terraform plan -var-file="terraform.tfvars"
        terraform apply -var-file="terraform.tfvars" -auto-approve
    else
        print_warn "Файл terraform.tfvars не найден, используются значения по умолчанию"
        terraform plan
        terraform apply -auto-approve
    fi
    
    print_info "Инфраструктура успешно развернута"
}

# Генерация Ansible инвентаря из Terraform outputs
generate_ansible_inventory() {
    print_info "Генерация Ansible инвентаря..."
    
    cd "$SCRIPT_DIR/infrastructure/terraform"
    terraform output -json > /tmp/terraform_outputs.json
    
    # Создание инвентаря на основе outputs
    python3 << EOF
import json
import sys

with open('/tmp/terraform_outputs.json', 'r') as f:
    outputs = json.load(f)

inventory = {
    'all': {
        'children': {
            'dmz_servers': {
                'hosts': {
                    'web-server': {'ansible_host': outputs['web_server_ip']['value'][0] if isinstance(outputs['web_server_ip']['value'], list) else outputs['web_server_ip']['value']},
                    'mail-server': {'ansible_host': outputs['mail_server_ip']['value'][0] if isinstance(outputs['mail_server_ip']['value'], list) else outputs['mail_server_ip']['value']},
                    'dns-server': {'ansible_host': outputs['dns_server_ip']['value'][0] if isinstance(outputs['dns_server_ip']['value'], list) else outputs['dns_server_ip']['value']}
                }
            },
            'internal_servers': {
                'hosts': {
                    'file-server': {'ansible_host': outputs['file_server_ip']['value'][0] if isinstance(outputs['file_server_ip']['value'], list) else outputs['file_server_ip']['value']},
                    'db-server': {'ansible_host': outputs['db_server_ip']['value'][0] if isinstance(outputs['db_server_ip']['value'], list) else outputs['db_server_ip']['value']},
                    'backup-server': {'ansible_host': outputs['backup_server_ip']['value'][0] if isinstance(outputs['backup_server_ip']['value'], list) else outputs['backup_server_ip']['value']},
                    'monitoring-server': {'ansible_host': outputs['monitoring_server_ip']['value'][0] if isinstance(outputs['monitoring_server_ip']['value'], list) else outputs['monitoring_server_ip']['value']}
                }
            },
            'development_servers': {
                'hosts': {
                    'dev-server': {'ansible_host': outputs['dev_server_ip']['value'][0] if isinstance(outputs['dev_server_ip']['value'], list) else outputs['dev_server_ip']['value']},
                    'test-server': {'ansible_host': outputs['test_server_ip']['value'][0] if isinstance(outputs['test_server_ip']['value'], list) else outputs['test_server_ip']['value']},
                    'ci-cd-server': {'ansible_host': outputs['cicd_server_ip']['value'][0] if isinstance(outputs['cicd_server_ip']['value'], list) else outputs['cicd_server_ip']['value']}
                }
            },
            'management_servers': {
                'hosts': {
                    'jump-server': {'ansible_host': outputs['jump_server_ip']['value'][0] if isinstance(outputs['jump_server_ip']['value'], list) else outputs['jump_server_ip']['value']}
                }
            }
        },
        'vars': {
            'ansible_user': 'ubuntu',
            'ansible_ssh_private_key_file': '~/.ssh/id_rsa',
            'ansible_ssh_common_args': '-o StrictHostKeyChecking=no'
        }
    }
}

import yaml
print(yaml.dump(inventory, default_flow_style=False))
EOF
    
    # Сохранение инвентаря
    python3 << EOF > "$SCRIPT_DIR/infrastructure/ansible/inventory_generated.yml"
import json
import yaml

with open('/tmp/terraform_outputs.json', 'r') as f:
    outputs = json.load(f)

inventory = {
    'all': {
        'children': {
            'dmz_servers': {
                'hosts': {
                    'web-server': {'ansible_host': outputs['web_server_ip']['value'][0] if isinstance(outputs['web_server_ip']['value'], list) else outputs['web_server_ip']['value']},
                    'mail-server': {'ansible_host': outputs['mail_server_ip']['value'][0] if isinstance(outputs['mail_server_ip']['value'], list) else outputs['mail_server_ip']['value']},
                    'dns-server': {'ansible_host': outputs['dns_server_ip']['value'][0] if isinstance(outputs['dns_server_ip']['value'], list) else outputs['dns_server_ip']['value']}
                }
            },
            'internal_servers': {
                'hosts': {
                    'file-server': {'ansible_host': outputs['file_server_ip']['value'][0] if isinstance(outputs['file_server_ip']['value'], list) else outputs['file_server_ip']['value']},
                    'db-server': {'ansible_host': outputs['db_server_ip']['value'][0] if isinstance(outputs['db_server_ip']['value'], list) else outputs['db_server_ip']['value']},
                    'backup-server': {'ansible_host': outputs['backup_server_ip']['value'][0] if isinstance(outputs['backup_server_ip']['value'], list) else outputs['backup_server_ip']['value']},
                    'monitoring-server': {'ansible_host': outputs['monitoring_server_ip']['value'][0] if isinstance(outputs['monitoring_server_ip']['value'], list) else outputs['monitoring_server_ip']['value']}
                }
            },
            'development_servers': {
                'hosts': {
                    'dev-server': {'ansible_host': outputs['dev_server_ip']['value'][0] if isinstance(outputs['dev_server_ip']['value'], list) else outputs['dev_server_ip']['value']},
                    'test-server': {'ansible_host': outputs['test_server_ip']['value'][0] if isinstance(outputs['test_server_ip']['value'], list) else outputs['test_server_ip']['value']},
                    'ci-cd-server': {'ansible_host': outputs['cicd_server_ip']['value'][0] if isinstance(outputs['cicd_server_ip']['value'], list) else outputs['cicd_server_ip']['value']}
                }
            },
            'management_servers': {
                'hosts': {
                    'jump-server': {'ansible_host': outputs['jump_server_ip']['value'][0] if isinstance(outputs['jump_server_ip']['value'], list) else outputs['jump_server_ip']['value']}
                }
            }
        },
        'vars': {
            'ansible_user': 'ubuntu',
            'ansible_ssh_private_key_file': '~/.ssh/id_rsa',
            'ansible_ssh_common_args': '-o StrictHostKeyChecking=no'
        }
    }
}

with open('$SCRIPT_DIR/infrastructure/ansible/inventory_generated.yml', 'w') as f:
    yaml.dump(inventory, f, default_flow_style=False, sort_keys=False)
EOF
    
    print_info "Ansible инвентарь сгенерирован"
}

# Ожидание готовности серверов
wait_for_servers() {
    print_info "Ожидание готовности серверов..."
    
    cd "$SCRIPT_DIR/infrastructure/terraform"
    SERVERS=$(terraform output -json | python3 -c "import json, sys; data=json.load(sys.stdin); print(' '.join([data['web_server_ip']['value'][0] if isinstance(data['web_server_ip']['value'], list) else data['web_server_ip']['value'], data['mail_server_ip']['value'][0] if isinstance(data['mail_server_ip']['value'], list) else data['mail_server_ip']['value'], data['dns_server_ip']['value'][0] if isinstance(data['dns_server_ip']['value'], list) else data['dns_server_ip']['value'], data['file_server_ip']['value'][0] if isinstance(data['file_server_ip']['value'], list) else data['file_server_ip']['value'], data['db_server_ip']['value'][0] if isinstance(data['db_server_ip']['value'], list) else data['db_server_ip']['value']]))")
    
    for IP in $SERVERS; do
        print_info "Ожидание готовности $IP..."
        timeout 300 bash -c "until ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$IP 'exit 0' 2>/dev/null; do sleep 5; done" || {
            print_warn "Сервер $IP не отвечает, но продолжаем..."
        }
    done
    
    print_info "Серверы готовы"
}

# Применение конфигураций через Ansible
apply_ansible_config() {
    print_info "Применение конфигураций через Ansible..."
    
    cd "$SCRIPT_DIR/infrastructure/ansible"
    
    INVENTORY_FILE="inventory_generated.yml"
    if [ ! -f "$INVENTORY_FILE" ]; then
        INVENTORY_FILE="inventory.yml"
    fi
    
    ansible-playbook -i "$INVENTORY_FILE" playbook.yml
    
    print_info "Конфигурации успешно применены"
}

# Главная функция
main() {
    print_info "Начало развертывания инфраструктуры офисной организации"
    
    check_requirements
    check_base_image
    init_terraform
    deploy_infrastructure
    generate_ansible_inventory
    wait_for_servers
    apply_ansible_config
    
    print_info "Развертывание завершено успешно!"
    print_info "Инфраструктура готова к использованию"
}

# Запуск главной функции
main "$@"

