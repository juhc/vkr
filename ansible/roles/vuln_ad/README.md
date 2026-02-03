# Роль `vuln_ad`

Роль применяет **AD/DC‑специфичные учебные уязвимости** на Domain Controller по списку ID.

> Управление остаётся по SSH (OpenSSH + PowerShell), как и в остальных Windows playbook.

## Использование

```yaml
- hosts: domain_controller
  gather_facts: yes
  roles:
    - role: vuln_ad
      vars:
        vuln_enabled:
          - ad.priv.user_in_domain_admins
          - ad.auth.asrep_roastable_user
```

## Переменные

- `vuln_enabled` (list[str]): список включённых уязвимостей (ID).
- `vuln_ad_domain_name` (string, default `training.local`): DNS‑имя домена (best-effort).
- `vuln_ad_weak_password` (string, default `password`): “слабый” пароль для демонстрации (vault не нужен, но можно).
- `vuln_ad_test_user` (string, default `StudentTest`): имя тестового доменного пользователя.

## Доступные уязвимости (ID)

- `ad.priv.user_in_domain_admins`
- `ad.auth.asrep_roastable_user`
- `ad.network.ldap_signing_disabled`
- `ad.gpo.password_policy_weak`
- `ad.gpo.account_lockout_disabled`
- `ad.gpo.llmnr_enabled`
- `ad.gpo.smb_signing_disabled`
- `ad.gpo.ntlmv1_allowed`
- `ad.gpo.firewall_disabled`
- `ad.gpo.defender_disabled`
- `ad.gpo.updates_disabled`
- `ad.gpo.powershell_logging_disabled`
- `ad.gpo.audit_disabled`
- `ad.gpo.eventlog_retention_low`
- `ad.gpo.rdp_open_to_all`
- `ad.gpo.winrm_insecure`
- `ad.gpo.no_lock_on_idle`

## Добавление новой уязвимости

1) Создайте файл `tasks/vulns/<id>.yml` (имя файла = ID).
2) Добавьте ID в `defaults/main.yml` → `vuln_ad_known`.
3) Включите ID в профиле `group_vars/.../vulnerabilities.yml` для `domain_controller`.
