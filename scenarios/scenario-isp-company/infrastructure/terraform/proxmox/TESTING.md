# Тестирование развертывания на Proxmox с ограниченными ресурсами

Это руководство поможет вам протестировать развертывание инфраструктуры на Proxmox, когда у вас ограниченные ресурсы и вы хотите запускать машины по одной.

## Быстрый старт

### Вариант 1: Использование скрипта (рекомендуется)

```bash
cd scenarios/scenario-isp-company/infrastructure/terraform/proxmox
./deploy-single-vm.sh
```

Скрипт предложит выбрать машину и автоматически настроит конфигурацию для развертывания только выбранной машины.

### Вариант 2: Ручная настройка через terraform.tfvars

1. Откройте `terraform.tfvars`:

```bash
nano terraform.tfvars
```

2. Установите все флаги в `false`, кроме нужной машины:

```hcl
# Для развертывания только RADIUS сервера:
enable_radius_server    = true
enable_billing_server   = false
enable_web_server       = false
enable_monitoring_server = false
enable_jump_server      = false
enable_kali_attacker     = false
```

3. Примените изменения:

```bash
terraform plan
terraform apply
```

## Примеры развертывания

### Пример 1: Только RADIUS сервер

```hcl
enable_radius_server    = true
enable_billing_server   = false
enable_web_server       = false
enable_monitoring_server = false
enable_jump_server      = false
enable_kali_attacker     = false
```

```bash
terraform apply
```

### Пример 2: Только веб-сервер

```hcl
enable_radius_server    = false
enable_billing_server   = false
enable_web_server       = true
enable_monitoring_server = false
enable_jump_server      = false
enable_kali_attacker     = false
```

### Пример 3: RADIUS + Веб-сервер

```hcl
enable_radius_server    = true
enable_billing_server   = false
enable_web_server       = true
enable_monitoring_server = false
enable_jump_server      = false
enable_kali_attacker     = false
```

## Минимальные ресурсы для каждой машины

Для тестирования можно уменьшить ресурсы в `terraform.tfvars`:

### RADIUS сервер (минимально)
```hcl
radius_cpu     = 1
radius_memory  = 2048
radius_disk_size = "20G"
```

### Веб-сервер (минимально)
```hcl
web_cpu     = 1
web_memory  = 2048
web_disk_size = "20G"
```

### Биллинговый сервер (минимально)
```hcl
billing_cpu     = 2
billing_memory  = 4096
billing_disk_size = "30G"
```

### Сервер мониторинга (минимально)
```hcl
monitoring_cpu     = 1
monitoring_memory  = 2048
monitoring_disk_size = "30G"
```

### Jump-сервер (минимально)
```hcl
jump_cpu     = 1
jump_memory  = 1024
jump_disk_size = "20G"
```

### Kali Linux (минимально)
```hcl
kali_cpu     = 2
kali_memory  = 4096
kali_disk_size = "50G"
```

## Последовательность тестирования

Рекомендуемый порядок развертывания для тестирования:

1. **RADIUS сервер** - самая простая машина, хороша для начала
2. **Веб-сервер** - для тестирования веб-уязвимостей
3. **Jump-сервер** - минимальные ресурсы
4. **Сервер мониторинга** - для тестирования мониторинга
5. **Биллинговый сервер** - требует больше ресурсов
6. **Kali Linux** - требует больше всего ресурсов

## Проверка развертывания

После развертывания машины:

```bash
# Проверить статус
terraform show

# Получить IP адрес
terraform output vm_ips

# Подключиться к машине
ssh platform-admin@<IP_ADDRESS>
```

## Удаление машины

Для удаления развернутой машины:

```bash
# Установите соответствующий флаг в false в terraform.tfvars
# Затем:
terraform destroy -target=module.<machine_name>[0]
```

Например, для удаления RADIUS сервера:

```bash
terraform destroy -target=module.radius_server[0]
```

## Проблемы и решения

### Ошибка: недостаточно ресурсов

**Решение**: Уменьшите CPU, RAM или disk_size в terraform.tfvars

### Ошибка: шаблон не найден

**Решение**: Убедитесь, что шаблон создан в Proxmox:
```bash
# Проверьте шаблоны через веб-интерфейс Proxmox
# или через CLI:
qm list | grep template
```

### Машина не запускается

**Решение**: 
1. Проверьте логи в веб-интерфейсе Proxmox
2. Проверьте доступные ресурсы на узле
3. Убедитесь, что шаблон настроен правильно

## Дополнительные советы

1. **Используйте снапшоты**: После успешного развертывания создайте снапшот в Proxmox для быстрого восстановления
2. **Мониторинг ресурсов**: Следите за использованием ресурсов через веб-интерфейс Proxmox
3. **Постепенное увеличение**: Начните с одной машины, затем добавляйте по одной для тестирования взаимодействия

## Следующие шаги

После успешного тестирования одной машины:

1. Примените конфигурацию через Ansible
2. Проверьте доступность сервисов
3. Протестируйте уязвимости
4. Добавьте следующую машину и повторите процесс

