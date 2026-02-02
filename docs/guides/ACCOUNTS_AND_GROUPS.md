# Пользователи и группы на стенде (Ansible)

Задача: для каждого стенда заранее описывать:
- какие пользователи должны существовать,
- какие у них группы/права,
- какие ключи/пароли используются (без хранения секретов в git).

## Где задавать

В каждом сценарии:

- `stands/<scenario>/infrastructure/ansible/group_vars/all/accounts.yml`

В репозитории лежит только пример:
- `accounts.yml.example`

## Формат (profiles)

`accounts_profiles` — словарь профилей по группам хостов из inventory:

Linux пример:

```yaml
accounts_profiles:
  linux_server:
    groups: ["sudo"]
    users:
      - name: ansible
        groups: ["sudo"]
        ssh_public_keys:
          - "ssh-ed25519 AAAA... admin@laptop"
```

Windows пример:

```yaml
accounts_profiles:
  windows_server:
    users:
      - name: ansible
        admin: true
        ssh_public_keys:
          - "ssh-ed25519 AAAA... admin@laptop"
```

## Как включается

Playbook’и стендов уже вызывают роль `vkr_accounts` перед уязвимостями:
- Linux: `linux-ws/playbook.yml`, `linux-server/playbook.yml`
- Windows: `windows-10/playbook.yml`, `windows-server/playbook.yml`, `domain-controller/playbook.yml`

## Пароли и секреты

Рекомендации:
- **не коммитить** `accounts.yml` если там есть пароли,
- использовать **Ansible Vault**:

```bash
ansible-vault create stands/<scenario>/infrastructure/ansible/group_vars/all/accounts.yml
```

или хранить `accounts.yml` локально (вне git) и передавать через `-e @...`/CI variables.

