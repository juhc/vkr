# Роль `vkr_vuln_windows`

Роль применяет **набор учебных уязвимостей** на Windows-хосте по списку ID.

## Использование

```yaml
- hosts: windows_workstation
  gather_facts: yes
  roles:
    - role: vkr_vuln_windows
      vars:
        vuln_enabled:
          - windows.auth.weak_admin_password
          - windows.remote.rdp_enabled
          - windows.firewall.disabled
```

## Переменные

- `vuln_enabled` (list[str]): список включённых уязвимостей (ID).
- `vkr_vuln_windows_weak_password` (string, default `password`): слабый пароль для демонстрации.
- `vkr_vuln_windows_testadmin_user` (string, default `TestAdmin`): имя лишнего admin пользователя.

## Доступные уязвимости (ID)

- `windows.auth.weak_admin_password`
- `windows.auth.no_password_policy`
- `windows.auth.guest_enabled`
- `windows.priv.testadmin_in_admins`
- `windows.remote.rdp_enabled`
- `windows.firewall.disabled`
- `windows.updates.disabled`
- `windows.defender.disabled` (best-effort)
- `windows.network.smb1_enabled` (best-effort)
- `windows.network.ntlmv1_enabled`
- `windows.audit.disabled`

## Добавление новой уязвимости

1) Создайте файл `tasks/vulns/<id>.yml` (имя файла = ID).
2) Добавьте ID в `defaults/main.yml` → `vkr_vuln_windows_known`.
3) Включите ID в профиле `group_vars/.../vulnerabilities.yml`.

