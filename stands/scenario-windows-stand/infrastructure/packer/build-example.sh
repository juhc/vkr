#!/bin/bash
# Пример скрипта для сборки всех шаблонов с использованием общих переменных

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Сборка шаблонов Windows через Packer"
echo "=========================================="

# Проверка наличия общих файлов переменных
if [ ! -f "$SCRIPT_DIR/variables.common.pkrvars.hcl" ]; then
    echo "ОШИБКА: Файл variables.common.pkrvars.hcl не найден!"
    echo "Создайте его из variables.common.pkrvars.hcl.example:"
    echo "  cp variables.common.pkrvars.hcl.example variables.common.pkrvars.hcl"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/variables.secrets.pkrvars.hcl" ]; then
    echo "ОШИБКА: Файл variables.secrets.pkrvars.hcl не найден!"
    echo "Создайте его из variables.secrets.pkrvars.hcl.example:"
    echo "  cp variables.secrets.pkrvars.hcl.example variables.secrets.pkrvars.hcl"
    exit 1
fi

# Сборка Windows 10 (рабочая станция)
if [ -d "$SCRIPT_DIR/windows-10" ]; then
    echo ""
    echo "Сборка шаблона Windows 10..."
    cd "$SCRIPT_DIR/windows-10"
    
    if [ ! -f "variables.pkrvars.hcl" ]; then
        echo "ОШИБКА: не найден variables.pkrvars.hcl"
        exit 1
    fi
    
    packer init .
    packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
    packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
fi

# Сборка Windows Server
if [ -d "$SCRIPT_DIR/windows-server" ]; then
    echo ""
    echo "Сборка шаблона Windows Server..."
    cd "$SCRIPT_DIR/windows-server"
    
    if [ ! -f "variables.pkrvars.hcl" ]; then
        echo "ОШИБКА: не найден variables.pkrvars.hcl"
        exit 1
    fi
    
    packer init .
    packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
    packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
fi

# Сборка Domain Controller
if [ -d "$SCRIPT_DIR/domain-controller" ]; then
    echo ""
    echo "Сборка шаблона Domain Controller..."
    cd "$SCRIPT_DIR/domain-controller"
    
    if [ ! -f "variables.pkrvars.hcl" ]; then
        echo "ОШИБКА: не найден variables.pkrvars.hcl"
        exit 1
    fi
    
    packer init .
    packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
    packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
fi

echo ""
echo "=========================================="
echo "Сборка завершена!"
echo "=========================================="
