# Управление уязвимостями в учебной инфраструктуре

## Обзор

Система позволяет выборочно включать/отключать категории уязвимостей для настройки уровня сложности обучения.

## Быстрый старт

### 1. Использование всех уязвимостей (по умолчанию)

```bash
# Просто запустите playbook - все уязвимости включены
ansible-playbook -i inventory.yml playbook.yml
```

### 2. Выборочное включение уязвимостей

```bash
# 1. Скопируйте пример конфигурации
cp group_vars/all/vulnerabilities.example.yml group_vars/all/vulnerabilities.yml

# 2. Отредактируйте файл, установив false для ненужных уязвимостей
nano group_vars/all/vulnerabilities.yml

# 3. Запустите playbook
ansible-playbook -i inventory.yml playbook.yml
```

### 3. Использование тегов для выборочного запуска

```bash
# Запустить только уязвимости аутентификации
ansible-playbook -i inventory.yml playbook.yml --tags "auth"

# Запустить только уязвимости SSH
ansible-playbook -i inventory.yml playbook.yml --tags "ssh"

# Запустить только уязвимости сети
ansible-playbook -i inventory.yml playbook.yml --tags "network"

# Исключить определенные категории
ansible-playbook -i inventory.yml playbook.yml --skip-tags "docker,backup"
```

## Структура конфигурации

Файл `group_vars/all/vulnerabilities.yml` содержит три основных раздела:

### Ubuntu Server (12 категорий)

```yaml
ubuntu_vulnerabilities:
  # Категория 1: Аутентификация
  auth_weak_passwords: true
  auth_no_pam_restrictions: true
  auth_no_account_lockout: true
  auth_no_password_expiry: true
  auth_wide_sudo_rights: true
  auth_no_mfa: true
  
  # Категория 2: SSH
  ssh_password_auth: true
  ssh_root_login: true
  ssh_weak_algorithms: true
  ssh_no_fail2ban: true
  
  # ... остальные категории
```

### Windows Server 2016 (10 категорий)

```yaml
windows_server_vulnerabilities:
  # Категория 1: Аутентификация
  auth_weak_passwords: true
  auth_no_password_policy: true
  # ... остальные категории
```

### Windows 10 Pro

```yaml
windows_client_vulnerabilities:
  auth_weak_passwords: true
  auth_uac_disabled: true
  # ... остальные
```

## Примеры использования

### Пример 1: Настройка для начинающих

Включить только базовые уязвимости:

```yaml
ubuntu_vulnerabilities:
  auth_weak_passwords: true
  ssh_password_auth: true
  ssh_root_login: true
  network_firewall_off: true
  updates_disabled: true
  files_wrong_permissions: true
  # Остальные отключить
  auth_no_account_lockout: false
  ssh_weak_algorithms: false
  files_shadow_vulnerabilities: false
  docker_no_protection: false
  kernel_no_hardening: false
```

### Пример 2: Только уязвимости аутентификации

```yaml
ubuntu_vulnerabilities:
  # Включить только категорию 1
  auth_weak_passwords: true
  auth_no_pam_restrictions: true
  auth_no_account_lockout: true
  auth_no_password_expiry: true
  auth_wide_sudo_rights: true
  auth_no_mfa: true
  
  # Остальные отключить
  ssh_password_auth: false
  network_firewall_off: false
  # ... и т.д.
```

### Пример 3: Продвинутый уровень (все включено)

```yaml
# Просто установите все в true или используйте файл по умолчанию
enable_all_vulnerabilities: true
```

## Теги для выборочного запуска

Playbook использует теги для удобного управления:

| Тег | Описание |
|-----|----------|
| `auth` | Уязвимости аутентификации |
| `ssh` | Уязвимости SSH |
| `network` | Уязвимости сети и firewall |
| `updates` | Уязвимости обновлений |
| `services` | Уязвимости служб |
| `files` | Уязвимости прав доступа |
| `web` | Уязвимости веб-сервисов |
| `logging` | Уязвимости логирования |
| `docker` | Уязвимости контейнеризации |
| `backup` | Уязвимости резервного копирования |
| `kernel` | Уязвимости ядра |
| `physical` | Физическая безопасность |

### Использование тегов

```bash
# Только уязвимости аутентификации и SSH
ansible-playbook -i inventory.yml playbook.yml --tags "auth,ssh"

# Все кроме контейнеризации и бэкапов
ansible-playbook -i inventory.yml playbook.yml --skip-tags "docker,backup"

# Только для Ubuntu Server
ansible-playbook -i inventory.yml playbook.yml --limit ubuntu-server --tags "auth"
```

## Уровни сложности

Можно использовать предустановленные уровни:

```yaml
difficulty_level: "beginner"      # Только базовые уязвимости
difficulty_level: "intermediate"  # Средний набор
difficulty_level: "advanced"      # Все уязвимости (по умолчанию)
```

## Проверка конфигурации

Перед запуском можно проверить, какие уязвимости будут применены:

```bash
# Показать переменные
ansible-playbook -i inventory.yml playbook.yml --list-tags

# Проверка синтаксиса
ansible-playbook -i inventory.yml playbook.yml --syntax-check

# Тестовый запуск (без изменений)
ansible-playbook -i inventory.yml playbook.yml --check
```

## Рекомендации

1. **Для начинающих:** Включите только категории 1-4 (аутентификация, SSH, сеть, обновления)
2. **Для среднего уровня:** Добавьте категории 5-8 (службы, файлы, веб, логирование)
3. **Для продвинутых:** Включите все категории, включая сложные (shadow, docker, kernel)

## Документация

Полное описание всех уязвимостей см. в:
- `../../docs/overview/machine-scenarios.md`

