# Роль `vkr_vuln_linux`

Роль применяет **набор учебных уязвимостей** на Linux-хосте по списку ID.

## Использование

```yaml
- hosts: linux_server
  become: yes
  roles:
    - role: vkr_vuln_linux
      vars:
        vuln_enabled:
          - linux.auth.weak_root_password
          - linux.ssh.root_login
          - linux.ssh.password_auth
```

## Переменные

- `vuln_enabled` (list[str]): список включённых уязвимостей (ID).
- `vkr_vuln_linux_weak_password` (string, default `password`): пароль для слабых учёток (хэшируется).
- `vkr_vuln_linux_extra_admin_user` (string, default `testadmin`): имя лишнего admin/sudo пользователя.

## Доступные уязвимости (ID)

- `linux.auth.weak_root_password`
- `linux.auth.no_password_policy`
- `linux.auth.extra_admin_user`
- `linux.sudo.nopasswd`
- `linux.ssh.root_login`
- `linux.ssh.password_auth`
- `linux.firewall.disabled`
- `linux.services.insecure_telnet`
- `linux.services.insecure_ftp`
- `linux.files.world_writable_secrets`
- `linux.updates.disabled`
- `linux.logging.disabled`
- `linux.cron.world_writable_cron`

## Добавление новой уязвимости

1) Создайте файл `tasks/vulns/<id>.yml` (имя файла = ID).
2) Добавьте ID в `defaults/main.yml` → `vkr_vuln_linux_known`.
3) Включите ID в профиле `group_vars/.../vulnerabilities.yml`.

