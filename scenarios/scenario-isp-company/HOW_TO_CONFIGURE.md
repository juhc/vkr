# Как настроить и изменить сценарий

Это руководство объясняет, как изменять уязвимости, настройки машин и параметры сценария.

## Быстрый старт

### 1. Основной файл конфигурации

Все настройки находятся в файле:
```
infrastructure/ansible/vulnerabilities.yml
```

Этот файл содержит все уязвимости и настройки для каждой машины.

### 2. Структура файла

Файл организован по типам серверов:

```yaml
global:                    # Общие настройки
  difficulty_level: "intermediate"
  enable_all_vulnerabilities: true

infrastructure_servers:    # Инфраструктурные серверы
  radius_server: ...

service_servers:          # Сервисные серверы
  billing_server: ...
  web_server: ...

management_servers:       # Управляющие серверы
  monitoring_server: ...
  jump_server: ...
```

## Примеры изменений

### Пример 1: Отключить все уязвимости

Откройте файл `vulnerabilities.yml` и измените:

```yaml
global:
  enable_all_vulnerabilities: false  # Было: true
```

Это отключит все уязвимости сразу.

### Пример 2: Изменить пароль базы данных RADIUS

Найдите секцию `infrastructure_servers.radius_server`:

```yaml
infrastructure_servers:
  radius_server:
    vulnerabilities:
      weak_db_password:
        enabled: true
        mysql_password: "MyNewStrongPassword123!"  # Измените здесь
```

### Пример 3: Отключить конкретную уязвимость

Чтобы отключить SQL инъекции на биллинговом сервере:

```yaml
service_servers:
  billing_server:
    vulnerabilities:
      sql_injection:
        enabled: false  # Было: true
```

### Пример 4: Изменить уровень сложности

```yaml
global:
  difficulty_level: "beginner"  # Варианты: beginner, intermediate, advanced
```

### Пример 5: Изменить версию WordPress

```yaml
service_servers:
  web_server:
    vulnerabilities:
      vulnerable_wordpress:
        enabled: true
        version: "5.9"  # Измените версию
```

## Использование скрипта управления

Для удобства можно использовать скрипт `manage-vulnerabilities.sh`:

### Показать текущую конфигурацию

```bash
cd scenarios/scenario-isp-company/infrastructure/ansible/scripts
./manage-vulnerabilities.sh show
```

### Включить все уязвимости

```bash
./manage-vulnerabilities.sh enable-all
```

### Отключить все уязвимости

```bash
./manage-vulnerabilities.sh disable-all
```

### Изменить уровень сложности

```bash
./manage-vulnerabilities.sh set-difficulty beginner
```

### Изменить пароль

```bash
./manage-vulnerabilities.sh change-password radius_server mysql "NewPassword123!"
```

### Проверить конфигурацию

```bash
./manage-vulnerabilities.sh validate
```

### Применить изменения

```bash
./manage-vulnerabilities.sh apply
```

## Пошаговые инструкции

### Шаг 1: Откройте файл конфигурации

```bash
cd scenarios/scenario-isp-company/infrastructure/ansible
nano vulnerabilities.yml
# или
code vulnerabilities.yml  # для VS Code
```

### Шаг 2: Найдите нужную секцию

Например, для изменения настроек веб-сервера найдите:

```yaml
service_servers:
  web_server:
    ip: "192.168.20.20"
    hostname: "web-server"
    
    vulnerabilities:
      vulnerable_wordpress:
        enabled: true
        version: "5.8"
```

### Шаг 3: Внесите изменения

Измените нужные параметры. Например:

```yaml
vulnerable_wordpress:
  enabled: false  # Отключить уязвимость WordPress
  version: "5.9"  # Изменить версию
```

### Шаг 4: Сохраните файл

Сохраните изменения в файле.

### Шаг 5: Примените изменения

```bash
# Вариант 1: Использовать скрипт
./scripts/manage-vulnerabilities.sh apply

# Вариант 2: Применить вручную через Ansible
ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
```

## Типичные задачи

### Задача 1: Создать сценарий для начинающих

```yaml
global:
  difficulty_level: "beginner"
  enable_all_vulnerabilities: true

# Отключить сложные уязвимости
service_servers:
  billing_server:
    vulnerabilities:
      sql_injection:
        enabled: false  # Отключить для начинающих
  
  web_server:
    vulnerabilities:
      xss:
        enabled: false  # Отключить XSS для начинающих
```

### Задача 2: Усилить безопасность (для продвинутых)

```yaml
global:
  enable_all_vulnerabilities: false  # Отключить все

# Включить только сложные уязвимости
service_servers:
  billing_server:
    vulnerabilities:
      sql_injection:
        enabled: true  # Оставить только SQL инъекции
```

### Задача 3: Изменить все пароли

Найдите все секции с паролями и измените:

```yaml
# RADIUS сервер
infrastructure_servers:
  radius_server:
    vulnerabilities:
      weak_db_password:
        mysql_password: "NewRadiusPassword123!"

# Биллинговый сервер
service_servers:
  billing_server:
    vulnerabilities:
      weak_db_password:
        postgresql_password: "NewBillingPassword123!"
```

### Задача 4: Добавить новую уязвимость

Добавьте новую секцию в соответствующий раздел:

```yaml
service_servers:
  web_server:
    vulnerabilities:
      # Существующие уязвимости...
      
      # Новая уязвимость
      insecure_file_uploads:
        enabled: true
        allow_dangerous_extensions: true
        no_file_size_limit: true
```

## Валидация изменений

Перед применением всегда проверяйте конфигурацию:

```bash
# Проверка синтаксиса YAML
python3 -c "import yaml; yaml.safe_load(open('vulnerabilities.yml'))"

# Проверка через скрипт
./scripts/manage-vulnerabilities.sh validate
```

## Резервное копирование

Перед изменениями создайте резервную копию:

```bash
cp vulnerabilities.yml vulnerabilities.yml.backup

# Или используйте скрипт
./scripts/manage-vulnerabilities.sh backup
```

## Интеграция с Ansible

Ansible playbook автоматически читает файл `vulnerabilities.yml`:

```yaml
# В playbook.yml
- name: Загрузить конфигурацию уязвимостей
  include_vars: vulnerabilities.yml

- name: Настроить RADIUS сервер
  include_role:
    name: radius-server
  vars:
    weak_passwords: "{{ infrastructure_servers.radius_server.vulnerabilities.weak_db_password.enabled }}"
    mysql_password: "{{ infrastructure_servers.radius_server.vulnerabilities.weak_db_password.mysql_password }}"
```

## Примеры конфигураций

### Конфигурация для начинающих

```yaml
global:
  difficulty_level: "beginner"
  enable_all_vulnerabilities: true
  use_weak_passwords: true

service_servers:
  web_server:
    vulnerabilities:
      vulnerable_wordpress:
        enabled: true
      sql_injection:
        enabled: false  # Отключено для начинающих
      xss:
        enabled: false  # Отключено для начинающих
```

### Конфигурация для продвинутых

```yaml
global:
  difficulty_level: "advanced"
  enable_all_vulnerabilities: true

# Все уязвимости включены
# Можно добавить дополнительные сложные сценарии
```

### Конфигурация без уязвимостей (для тестирования)

```yaml
global:
  enable_all_vulnerabilities: false
  use_weak_passwords: false
  disable_auto_updates: false
```

## Часто задаваемые вопросы

### Как добавить новую машину?

1. Добавьте описание машины в `vulnerabilities.yml`
2. Создайте соответствующую роль Ansible
3. Добавьте машину в inventory
4. Обновите документацию

### Как изменить IP адрес машины?

Измените IP в файле `vulnerabilities.yml`:

```yaml
infrastructure_servers:
  radius_server:
    ip: "192.168.10.20"  # Новый IP
```

Также обновите:
- `network-topology.md`
- `machine-scenarios.md`
- Ansible inventory

### Как добавить новую уязвимость?

1. Добавьте описание в `vulnerabilities.yml`
2. Создайте задачи в Ansible роли для применения уязвимости
3. Обновите документацию в `machine-scenarios.md`

### Как временно отключить машину?

Установите `enabled: false` для всех уязвимостей этой машины или закомментируйте секцию.

## Дополнительные ресурсы

- **Подробная документация**: `infrastructure/ansible/README_VULNERABILITIES.md`
- **Описание машин**: `machine-scenarios.md`
- **Сетевая топология**: `network-topology.md`
- **Документация Ansible**: https://docs.ansible.com/

## Получение помощи

Если у вас возникли вопросы:

1. Проверьте документацию в `README_VULNERABILITIES.md`
2. Проверьте примеры в этом файле
3. Используйте `./manage-vulnerabilities.sh help` для справки по скрипту

