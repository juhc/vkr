# Terraform конфигурация для учебной инфраструктуры

## Описание

Terraform конфигурация для автоматического развертывания Ubuntu Server с уязвимостями ОС.

## Использование

### Инициализация

```bash
terraform init
```

### Настройка переменных

Переменные можно задать через:
1. Переменные окружения: `export TF_VAR_ssh_public_key="..."`
2. Файл `terraform.tfvars` (создать вручную)
3. Командная строка: `terraform apply -var="ssh_public_key=..."`

### План развертывания

```bash
terraform plan
```

### Развертывание

```bash
terraform apply
```

### Удаление

```bash
terraform destroy
```

## Переменные

- `ssh_public_key` - SSH публичный ключ для доступа к Ubuntu Server
- `base_image_path` - Путь к образу Ubuntu Cloud Image (по умолчанию: `/var/lib/libvirt/images/focal-server-cloudimg-amd64.img`)
- `disk_pool` - Имя пула дисков libvirt (по умолчанию: `default`)
- `network_name` - Имя сети libvirt (по умолчанию: `default`)

## Выводы

После развертывания доступны:
- `ubuntu_server_ip` - IP адрес Ubuntu Server
- `ubuntu_server_name` - Имя виртуальной машины
- `all_machines` - Все IP адреса машин

## Примечания

- Windows машины (Server 2016 и 10 Pro) требуют ручной установки
- IP адреса Windows машин указаны статически в outputs
- Для Windows используйте virt-manager или virt-install

