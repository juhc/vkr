# Админ-доступ для операторов стенда (до развертывания)

Цель: у каждой машины **всегда** есть “операторский” пользователь с админскими правами, а пароль/ключ можно задать **до** запуска VM.

## Linux (cloud-init)

Linux VM создаются из cloud-init template, поэтому учётка задаётся прямо в Terraform/Proxmox cloud-init.

Гарантия:
- `ciuser` — операторский пользователь (рекомендуется `ansible`)
- `sshkeys` — ключ администратора
- `cipassword` — пароль (опционально), чтобы можно было войти в консоль без SSH

Где настраивать:
- `stands/linux-stand/infrastructure/terraform/*/terraform.tfvars` (локальный файл, не коммитится)

Пример (в `terraform.tfvars`):

```hcl
linux_server_user     = "ansible"
linux_server_password = "StrongTempPass123!"
ssh_public_key        = "ssh-ed25519 AAAA... admin@laptop"
proxmox_bridge        = "vmbr0"
use_dhcp              = false
cidr_prefix           = 24
```

## Windows (Packer template + Terraform)

Windows VM клонируются из Packer template. В template должен быть создан локальный админ‑пользователь (рекомендуется `ansible`) и включён OpenSSH Server.

Чтобы можно было менять креды **до развертывания VM**, Terraform делает опциональный “bootstrap” по SSH:
- заходит по `bootstrap_admin_password` (пароль, который вшит в template)
- если задан `admin_password` — меняет пароль
- если задан `admin_ssh_public_key` — добавляет ключ в `authorized_keys`

Где настраивать:
- `stands/windows-stand/infrastructure/terraform/*/terraform.tfvars` (локальный файл, не коммитится)

Пример:

```hcl
admin_user = "ansible"
bootstrap_admin_password = "TemplatePassword123!"  # чтобы Terraform смог зайти

admin_password       = "StrongTempPass123!"
admin_ssh_public_key = "ssh-ed25519 AAAA... admin@laptop"
```

Примечания:
- Если вы не хотите менять пароль/ключ — оставьте `admin_password=""` и `admin_ssh_public_key=""` (Terraform ничего не делает).
- Для работы bootstrap нужно, чтобы у VM был доступен SSH (порт 22) и IP был достижим.

