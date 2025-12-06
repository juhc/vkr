# Быстрый старт: Выборочное включение уязвимостей

## ✅ Да, можно выбрать какие уязвимости будут на машинах!

## Способ 1: Использование файла конфигурации (Рекомендуется)

### Шаг 1: Создайте файл конфигурации

```bash
cd infrastructure/ansible
cp group_vars/all/vulnerabilities.example.yml group_vars/all/vulnerabilities.yml
```

### Шаг 2: Отредактируйте конфигурацию

Откройте `group_vars/all/vulnerabilities.yml` и установите `false` для ненужных уязвимостей:

```yaml
ubuntu_vulnerabilities:
  # Включить только базовые уязвимости
  auth_weak_passwords: true              # ✅ Включить
  ssh_password_auth: true                # ✅ Включить
  ssh_root_login: true                  # ✅ Включить
  network_firewall_off: true            # ✅ Включить
  
  # Отключить сложные уязвимости
  files_shadow_vulnerabilities: false    # ❌ Отключить
  docker_no_protection: false           # ❌ Отключить
  kernel_no_hardening: false            # ❌ Отключить
```

### Шаг 3: Запустите playbook

```bash
ansible-playbook -i inventory.yml playbook.yml
```

## Способ 2: Использование тегов (После обновления playbook)

```bash
# Только уязвимости аутентификации
ansible-playbook -i inventory.yml playbook.yml --tags "auth"

# Только уязвимости SSH
ansible-playbook -i inventory.yml playbook.yml --tags "ssh"

# Все кроме контейнеризации
ansible-playbook -i inventory.yml playbook.yml --skip-tags "docker"
```

## Способ 3: Переменные командной строки

```bash
# Отключить конкретную уязвимость
ansible-playbook -i inventory.yml playbook.yml \
  -e "ubuntu_vulnerabilities_auth_weak_passwords=false"

# Включить только SSH уязвимости
ansible-playbook -i inventory.yml playbook.yml \
  -e "ubuntu_vulnerabilities_ssh_password_auth=true" \
  -e "ubuntu_vulnerabilities_ssh_root_login=true" \
  -e "ubuntu_vulnerabilities_auth_weak_passwords=false"
```

## Примеры конфигураций

### Для начинающих (базовые уязвимости)

```yaml
ubuntu_vulnerabilities:
  auth_weak_passwords: true
  ssh_password_auth: true
  ssh_root_login: true
  network_firewall_off: true
  updates_disabled: true
  files_wrong_permissions: true
  # Остальные: false
```

### Для среднего уровня

```yaml
ubuntu_vulnerabilities:
  # Категории 1-6 включить
  auth_weak_passwords: true
  ssh_password_auth: true
  network_firewall_off: true
  updates_disabled: true
  services_unnecessary_enabled: true
  files_wrong_permissions: true
  # Сложные отключить
  files_shadow_vulnerabilities: false
  docker_no_protection: false
```

### Для продвинутых (все включено)

```yaml
# Просто используйте файл по умолчанию или установите все в true
enable_all_vulnerabilities: true
```

## Текущий статус

⚠️ **Важно:** Сейчас playbook нужно обновить для поддержки переменных. 

**Что уже готово:**
- ✅ Файл конфигурации `vulnerabilities.yml`
- ✅ Пример конфигурации `vulnerabilities.example.yml`
- ✅ Документация

**Что нужно сделать:**
- ⚠️ Обновить `playbook.yml`, добавив условия `when:` к каждой категории задач

См. `PLAYBOOK_UPDATE_GUIDE.md` для инструкций по обновлению.

## Быстрое решение (временное)

Пока playbook не обновлен, можно:

1. **Комментировать ненужные секции** в playbook.yml
2. **Использовать теги** (если они уже добавлены)
3. **Создать отдельные playbook** для разных уровней сложности

## Документация

- Полное руководство: `README_VULNERABILITIES.md`
- Примеры обновления: `PLAYBOOK_UPDATE_GUIDE.md`
- Описание уязвимостей: `../../docs/overview/machine-scenarios.md`

