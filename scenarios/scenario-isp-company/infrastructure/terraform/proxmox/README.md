# Развертывание инфраструктуры ISP компании на Proxmox

Этот каталог содержит конфигурацию Terraform для развертывания инфраструктуры на удаленном сервере Proxmox VE.

## Требования

### На стороне Proxmox

1. **Proxmox VE 6.0+** установлен и настроен
2. **API доступ** настроен с токеном
3. **Шаблоны ВМ** созданы:
   - Ubuntu 20.04 template (для основных серверов)
   - Kali Linux template (для машины атакующего)

### На стороне управления

1. **Terraform 1.0+**
2. **Доступ к API Proxmox** (токен или пользователь/пароль)

## Подготовка Proxmox

### 1. Создание API токена

1. Войдите в веб-интерфейс Proxmox
2. Перейдите в **Datacenter → Permissions → API Tokens**
3. Нажмите **Add**
4. Заполните:
   - **Token ID**: `terraform@pve!terraform-token`
   - **User**: выберите пользователя (или создайте отдельного)
   - **Privilege Separation**: включите для безопасности
5. Сохраните **Token Secret** (он показывается только один раз!)

### 2. Создание шаблона Ubuntu

```bash
# На Proxmox сервере или через веб-интерфейс

# 1. Скачайте Ubuntu Cloud Image
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# 2. Создайте ВМ через веб-интерфейс или CLI:
qm create 9000 --name ubuntu-20.04-template --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

### 3. Создание шаблона Kali Linux

```bash
# Скачайте образ Kali Linux
wget https://cdimage.kali.org/kali-2023.4/kali-linux-2023.4-qemu-amd64.qcow2

# Создайте ВМ и преобразуйте в шаблон аналогично Ubuntu
```

## Настройка проекта

### 1. Копирование конфигурации

```bash
cd scenarios/scenario-isp-company/infrastructure/terraform/proxmox
cp terraform.tfvars.example terraform.tfvars
```

### 2. Редактирование terraform.tfvars

Откройте `terraform.tfvars` и заполните:

```hcl
proxmox_api_url          = "https://your-proxmox-server:8006/api2/json"
proxmox_api_token_id     = "terraform@pve!terraform-token"
proxmox_api_token_secret = "your-secret-here"
proxmox_target_node      = "proxmox-node-1"
proxmox_template_name    = "ubuntu-20.04-template"
```

### 3. Настройка SSH ключа

Убедитесь, что у вас есть SSH ключ:

```bash
# Если нет, создайте:
ssh-keygen -t ed25519 -C "terraform@proxmox"

# Укажите путь в terraform.tfvars:
ssh_public_key = file("~/.ssh/id_ed25519.pub")
```

## Развертывание

### 1. Инициализация Terraform

```bash
terraform init
```

### 2. Планирование изменений

```bash
terraform plan
```

### 3. Применение конфигурации

```bash
terraform apply
```

Terraform создаст все виртуальные машины на Proxmox.

### 4. Получение информации о ВМ

```bash
# Показать IP адреса
terraform output vm_ips

# Показать имена ВМ
terraform output vm_names
```

## Использование с Ansible

После развертывания Terraform, используйте выводы для создания Ansible inventory:

```bash
# Генерация inventory из Terraform outputs
terraform output -json vm_ips | jq -r '
  to_entries | .[] | 
  "\(.key) ansible_host=\(.value)"
' > ../../ansible/inventory.ini
```

Или используйте динамический inventory на основе Terraform state.

## Удаление инфраструктуры

```bash
terraform destroy
```

⚠️ **Внимание**: Это удалит все созданные виртуальные машины!

## Устранение проблем

### Ошибка подключения к API

1. Проверьте URL и порт (обычно 8006)
2. Убедитесь, что токен правильный
3. Для самоподписанных сертификатов установите `proxmox_tls_insecure = true`

### ВМ не создается

1. Проверьте, что шаблон существует
2. Убедитесь, что узел указан правильно
3. Проверьте доступное место на хранилище

### Проблемы с сетью

1. Убедитесь, что сетевой мост существует
2. Проверьте настройки VLAN (если используются)
3. Убедитесь, что IP адреса не конфликтуют

## Дополнительные ресурсы

- [Документация провайдера Proxmox](https://registry.terraform.io/providers/telmate/proxmox/latest/docs)
- [Документация Proxmox VE](https://pve.proxmox.com/pve-docs/)
- [Общая документация развертывания](../DEPLOYMENT.md)

