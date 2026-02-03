# Ansible → Windows по SSH (для клонов шаблонов)

Эти Packer-шаблоны настраивают **OpenSSH Server** внутри Windows (порт **22**), чтобы после клонирования вы могли управлять VM через Ansible по SSH (без WinRM).

## Требования на стороне Windows шаблона

- Служба **`sshd`** включена и запущена
- Открыт порт **TCP/22**
- В реестре задан `HKLM:\SOFTWARE\OpenSSH\DefaultShell` на PowerShell

Это делается скриптом `sources/$OEM$/$$/Setup/Scripts/setup.ps1` в кастомном ISO.

## Пример inventory.ini

```ini
[windows]
win10-01 ansible_host=192.168.0.120
win11-01 ansible_host=192.168.0.121

[windows:vars]
ansible_connection=ssh
ansible_user=Administrator
ansible_password=TempPassword123!
ansible_port=22
ansible_shell_type=powershell
ansible_shell_executable=powershell.exe

# Чтобы не упираться в hostkey при авторазвертывании:
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

## Быстрый тест

```bash
ansible -i inventory.ini windows -m win_ping
```

## Рекомендации (безопасность)

- Лучше использовать отдельного пользователя (не `Administrator`) и ключи SSH.
- Пароли/токены храните в `ansible-vault`.
- Отключайте `StrictHostKeyChecking=no` после первичной автоматизации.

