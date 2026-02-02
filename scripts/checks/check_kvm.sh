#!/bin/bash
# Скрипт для проверки и загрузки модулей KVM

echo "=== Проверка поддержки виртуализации ==="
echo "Проверка флагов CPU:"
egrep -c '(vmx|svm)' /proc/cpuinfo
echo ""

echo "=== Проверка текущих модулей KVM ==="
lsmod | grep kvm
echo ""

echo "=== Попытка загрузки модулей KVM ==="
# Определяем тип процессора
if grep -q vmx /proc/cpuinfo 2>/dev/null; then
    echo "Обнаружен Intel CPU, загружаем kvm_intel..."
    modprobe kvm_intel 2>&1
elif grep -q svm /proc/cpuinfo 2>/dev/null; then
    echo "Обнаружен AMD CPU, загружаем kvm_amd..."
    modprobe kvm_amd 2>&1
else
    echo "ВНИМАНИЕ: CPU не показывает поддержку виртуализации!"
    echo "Попытка загрузки базового модуля kvm..."
    modprobe kvm 2>&1
    echo ""
    echo "Попытка загрузки kvm_intel (для Intel)..."
    modprobe kvm_intel 2>&1
    echo ""
    echo "Попытка загрузки kvm_amd (для AMD)..."
    modprobe kvm_amd 2>&1
fi

echo ""
echo "=== Проверка модулей после загрузки ==="
lsmod | grep kvm
echo ""

echo "=== Проверка устройства /dev/kvm ==="
if [ -e /dev/kvm ]; then
    echo "✓ /dev/kvm существует"
    ls -l /dev/kvm
else
    echo "✗ /dev/kvm не существует - KVM не работает"
fi

echo ""
echo "=== Проверка через systemd ==="
systemctl status libvirtd 2>/dev/null | head -5 || echo "libvirtd не запущен или не установлен"

echo ""
echo "=== Информация о системе ==="
echo "Тип виртуализации (если в VM):"
systemd-detect-virt 2>/dev/null || echo "Не обнаружено"
echo ""
echo "Информация о системе:"
dmidecode -s system-product-name 2>/dev/null || echo "Недоступно"
