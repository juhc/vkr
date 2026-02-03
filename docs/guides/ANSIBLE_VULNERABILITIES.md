# Уязвимости через Ansible: переиспользуемая схема

Цель: уметь **включать/выключать уязвимости “по списку”** для каждой ОС/ВМ, без интерактивных скриптов.

## Как устроено

- Переиспользуемые роли находятся в `ansible/roles/`:
  - `vuln_linux` — уязвимости Linux
  - `vuln_windows` — уязвимости Windows
- В сценариях playbook’и тонкие: они только передают список `vuln_enabled` из `group_vars`.

Каталог (ID → категория → проверка): `docs/guides/VULNERABILITY_CATALOG.md`.

Админ-доступ (как заранее задать пароль/ключ): `docs/guides/ADMIN_ACCESS.md`.

Пользователи/группы на стенде: используйте `accounts_profiles` в
`stands/<scenario>/infrastructure/ansible/group_vars/all/accounts.yml` (см. `accounts.yml.example`) и роль `accounts`.

## Где включать/выключать уязвимости

В каждом сценарии:

- `stands/<scenario>/infrastructure/ansible/group_vars/all/vulnerabilities.yml`

Там описаны **профили** (списки ID) для групп хостов (например `linux_server`, `windows_workstation`).

Чтобы отключить уязвимость — просто удалите её ID из списка профиля.

## Как переиспользовать в новом сценарии

1) Скопируйте структуру `stands/*-stand/infrastructure/ansible`.
2) Оставьте playbook’и как есть (они уже используют роли из `ansible/roles/`).
3) Заполните `inventory.yml`.
4) Настройте профили в `group_vars/all/vulnerabilities.yml`.

Важно: в `infrastructure/ansible/ansible.cfg` уже задан `roles_path` на `../../../../ansible/roles`.

## Как добавить новую уязвимость

### Linux

1) Создайте файл: `ansible/roles/vuln_linux/tasks/vulns/<id>.yml`
2) Добавьте `<id>` в:
   - `ansible/roles/vuln_linux/defaults/main.yml` → `vuln_linux_known`
3) Добавьте ID в нужный профиль сценария (см. `group_vars/.../vulnerabilities.yml`).

### Windows

Аналогично, но в роли `vuln_windows`.

## Пример: включить слабые пароли и открыть удалённый доступ

- Linux server:
  - `linux.auth.weak_root_password`
  - `linux.ssh.root_login`
  - `linux.ssh.password_auth`
  - `linux.firewall.disabled`
- Windows WS:
  - `windows.auth.weak_admin_password`
  - `windows.remote.rdp_enabled`
  - `windows.firewall.disabled`

