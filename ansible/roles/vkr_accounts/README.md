# Роль `vkr_accounts`

Назначение: создать **набор групп и пользователей** на хосте (Linux/Windows) для конкретного стенда.

Идея: в сценарии вы задаёте `accounts_profiles.<group>` в `group_vars/all/accounts.yml`, а playbook передаёт список пользователей/групп в роль.

## Переменные

- `vkr_accounts_groups` (list[str]): группы, которые надо создать (Linux).
- `vkr_accounts_users` (list[dict]): пользователи.

Формат `vkr_accounts_users`:

```yaml
vkr_accounts_users:
  - name: ansible
    password: ""            # опционально; на Linux хэшируется, на Windows задаётся как есть
    groups: [sudo]          # Linux: локальные группы; Windows: локальные группы (Administrators и т.п.)
    admin: true             # Windows: добавит в Administrators (если groups не указаны)
    ssh_public_keys: []     # Linux: добавит через authorized_key; Windows: положит в %USERPROFILE%\.ssh\authorized_keys
```

## Рекомендации по безопасности

- Не храните реальные пароли в git. Используйте:
  - Ansible Vault, либо
  - переменные окружения/CI secrets, либо
  - локальный файл `accounts.yml` вне репозитория.

