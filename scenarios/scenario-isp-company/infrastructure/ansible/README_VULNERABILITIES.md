# Управление уязвимостями и настройками машин

Этот документ описывает, как изменять уязвимости и настройки машин в сценарии ISP-компании.

## Структура конфигурации

Все уязвимости и настройки определяются в файле `vulnerabilities.yml`. Этот файл использует структуру YAML и позволяет легко включать/отключать уязвимости и изменять параметры.

## Основные принципы

1. **Модульность**: Каждая уязвимость может быть включена или отключена независимо
2. **Гранулярность**: Можно управлять отдельными аспектами уязвимостей
3. **Безопасность по умолчанию**: При отключении уязвимости применяются безопасные настройки

## Структура файла vulnerabilities.yml

```yaml
global:
  difficulty_level: "intermediate"  # Уровень сложности
  enable_all_vulnerabilities: true  # Включить все уязвимости
  use_weak_passwords: true         # Использовать слабые пароли
  disable_auto_updates: true       # Отключить автообновления

client_servers:
  pppoe_server:
    ip: "192.168.10.10"
    vulnerabilities:
      weak_passwords:
        enabled: true
        root_password: "admin123"
```

## Как изменить уязвимости

### 1. Включение/отключение уязвимости

Чтобы отключить уязвимость, установите `enabled: false`:

```yaml
pppoe_server:
  vulnerabilities:
    weak_passwords:
      enabled: false  # Отключить слабые пароли
```

### 2. Изменение паролей

Измените значение пароля в соответствующей секции:

```yaml
radius_server:
  vulnerabilities:
    weak_db_password:
      enabled: true
      mysql_password: "MyNewPassword123!"  # Изменить пароль
```

### 3. Изменение уровня сложности

Измените `difficulty_level` в секции `global`:

```yaml
global:
  difficulty_level: "beginner"  # или "intermediate", "advanced"
```

### 4. Отключение всех уязвимостей

Установите `enable_all_vulnerabilities: false`:

```yaml
global:
  enable_all_vulnerabilities: false
```

## Примеры конфигураций

### Начальный уровень (beginner)

```yaml
global:
  difficulty_level: "beginner"
  enable_all_vulnerabilities: true
  use_weak_passwords: true

# Включить только базовые уязвимости
web_server:
  vulnerabilities:
    vulnerable_wordpress:
      enabled: true
    sql_injection:
      enabled: false  # Отключить для начинающих
    xss:
      enabled: false  # Отключить для начинающих
```

### Средний уровень (intermediate)

```yaml
global:
  difficulty_level: "intermediate"
  enable_all_vulnerabilities: true

# Включить все уязвимости веб-сервера
web_server:
  vulnerabilities:
    vulnerable_wordpress:
      enabled: true
    sql_injection:
      enabled: true
    xss:
      enabled: true
```

### Продвинутый уровень (advanced)

```yaml
global:
  difficulty_level: "advanced"
  enable_all_vulnerabilities: true

# Включить все уязвимости, включая сетевые
network_vulnerabilities:
  snmp:
    enabled: true
  open_ports:
    enabled: true
  insecure_protocols:
    enabled: true
```

## Применение изменений

После изменения файла `vulnerabilities.yml`, примените изменения с помощью Ansible:

```bash
# Перейти в директорию сценария
cd scenarios/scenario-isp-company/infrastructure/ansible

# Применить конфигурацию
ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
```

## Специфичные настройки по серверам

### PPPoE сервер

```yaml
pppoe_server:
  vulnerabilities:
    weak_passwords:
      enabled: true
      root_password: "admin123"
    
    open_management_ports:
      enabled: true
      ssh_from_client_network: true
      web_interface_without_auth: true
```

### RADIUS сервер

```yaml
radius_server:
  vulnerabilities:
    weak_db_password:
      enabled: true
      mysql_password: "radius123"
      remote_db_access: true
    
    client_data_leak:
      enabled: true
      plaintext_passwords: true
      sensitive_data_in_logs: true
```

### Веб-сервер

```yaml
web_server:
  vulnerabilities:
    vulnerable_wordpress:
      enabled: true
      version: "5.8"
      outdated_plugins: true
    
    sql_injection:
      enabled: true
      vulnerable_custom_plugins: true
      no_input_validation: true
```

### Биллинговый сервер

```yaml
billing_server:
  vulnerabilities:
    sql_injection:
      enabled: true
      vulnerable_code: true
      no_prepared_statements: true
    
    client_data_leak:
      enabled: true
      plaintext_personal_data: true
      unencrypted_payment_info: true
```

## Настройки для обучения

В секции `learning_settings` можно настроить параметры для обучения:

```yaml
learning_settings:
  log_detail_level: "debug"        # Уровень детализации логов
  verbose_error_messages: true     # Подробные сообщения об ошибках
  save_command_history: true       # Сохранять историю команд
  enable_hints: false              # Включить подсказки
```

## Валидация конфигурации

Перед применением конфигурации рекомендуется проверить её корректность:

```bash
# Проверка синтаксиса YAML
python -c "import yaml; yaml.safe_load(open('vulnerabilities.yml'))"

# Проверка с помощью Ansible
ansible-playbook --syntax-check playbook.yml -e @vulnerabilities.yml
```

## Резервное копирование

Перед изменением конфигурации рекомендуется создать резервную копию:

```bash
cp vulnerabilities.yml vulnerabilities.yml.backup
```

## Примеры сценариев

### Сценарий 1: Только веб-уязвимости

```yaml
global:
  enable_all_vulnerabilities: false

web_server:
  vulnerabilities:
    vulnerable_wordpress:
      enabled: true
    sql_injection:
      enabled: true
    xss:
      enabled: true
```

### Сценарий 2: Только уязвимости баз данных

```yaml
global:
  enable_all_vulnerabilities: false

radius_server:
  vulnerabilities:
    weak_db_password:
      enabled: true

billing_server:
  vulnerabilities:
    weak_db_password:
      enabled: true
    sql_injection:
      enabled: true
```

### Сценарий 3: Комплексный пентест

```yaml
global:
  enable_all_vulnerabilities: true
  difficulty_level: "advanced"
```

## Интеграция с Ansible

Ansible playbook автоматически читает файл `vulnerabilities.yml` и применяет соответствующие настройки:

```yaml
# В playbook.yml
- name: Применить уязвимости
  include_vars: vulnerabilities.yml
  
- name: Настроить PPPoE сервер
  include_role:
    name: pppoe-server
  vars:
    weak_passwords: "{{ client_servers.pppoe_server.vulnerabilities.weak_passwords.enabled }}"
    root_password: "{{ client_servers.pppoe_server.vulnerabilities.weak_passwords.root_password }}"
```

## Дополнительные ресурсы

- [Документация Ansible](https://docs.ansible.com/)
- [YAML синтаксис](https://yaml.org/spec/1.2/spec.html)
- [Описание уязвимостей](machine-scenarios.md)

