# Структура Ansible для проекта киберучений

## Обзор структуры Ansible

Ansible структура организована для обеспечения модульности, переиспользования и удобства управления конфигурациями учебных сценариев.

## Основная структура (ansible/)

```
ansible/
├── ansible.cfg                    # Основная конфигурация Ansible
├── requirements.yml                # Зависимости Ansible
├── vault/                         # Ansible Vault файлы
│   ├── secrets.yml                # Основные секреты
│   ├── passwords.yml              # Пароли
│   └── certificates.yml           # Сертификаты
├── inventories/                   # Инвентари для разных окружений
├── playbooks/                     # Плейбуки
├── roles/                         # Роли Ansible
├── group_vars/                    # Переменные групп
├── host_vars/                     # Переменные хостов
├── collections/                   # Ansible Collections
└── scripts/                       # Скрипты для Ansible
```

## Конфигурация Ansible (ansible.cfg)

```ini
[defaults]
# Основные настройки
inventory = inventories/production/hosts.yml
host_key_checking = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 86400

# Настройки выполнения
forks = 10
timeout = 30
poll_interval = 0.001
retry_files_enabled = False
retry_files_save_path = ~/.ansible-retry

# Настройки вывода
stdout_callback = yaml
bin_ansible_callbacks = True
display_skipped_hosts = False
display_ok_hosts = True

# Настройки SSH
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

# Настройки Vault
vault_password_file = ~/.vault_pass

[inventory]
# Настройки инвентаря
enable_plugins = host_list, script, auto, yaml, ini, toml

[privilege_escalation]
# Настройки привилегий
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[colors]
# Цвета вывода
highlight = white
verbose = blue
warn = bright purple
error = red
debug = dark gray
deprecate = purple
skip = cyan
unreachable = red
ok = green
changed = yellow
diff_add = green
diff_remove = red
diff_lines = cyan
```

## Структура инвентарей (inventories/)

```
inventories/
├── production/                   # Продакшн инвентарь
│   ├── hosts.yml                 # Основной файл хостов
│   ├── group_vars/               # Переменные групп
│   │   ├── all.yml
│   │   ├── web_servers.yml
│   │   ├── database_servers.yml
│   │   └── monitoring_servers.yml
│   └── host_vars/                # Переменные хостов
│       ├── web-server-01.yml
│       ├── database-01.yml
│       └── monitoring-01.yml
├── staging/                      # Тестовый инвентарь
│   ├── hosts.yml
│   ├── group_vars/
│   └── host_vars/
└── development/                  # Инвентарь разработки
    ├── hosts.yml
    ├── group_vars/
    └── host_vars/
```

### Пример hosts.yml
```yaml
all:
  children:
    web_servers:
      hosts:
        web-server-01:
          ansible_host: 192.168.100.10
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/lab_key
        web-server-02:
          ansible_host: 192.168.100.11
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/lab_key
      vars:
        http_port: 80
        https_port: 443
        ssl_enabled: true
    
    database_servers:
      hosts:
        database-01:
          ansible_host: 192.168.100.20
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/lab_key
      vars:
        mysql_port: 3306
        mysql_root_password: "{{ vault_mysql_root_password }}"
    
    monitoring_servers:
      hosts:
        monitoring-01:
          ansible_host: 192.168.100.30
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/lab_key
      vars:
        prometheus_port: 9090
        grafana_port: 3000
    
    scenario_1:
      children:
        web_servers:
        database_servers:
      vars:
        scenario_name: "unpatched-vulnerability"
        scenario_id: "scenario-1"
```

## Структура плейбуков (playbooks/)

```
playbooks/
├── common/                       # Общие плейбуки
│   ├── system-hardening.yml     # Усиление системы
│   ├── monitoring-setup.yml     # Настройка мониторинга
│   ├── backup-config.yml        # Настройка резервного копирования
│   ├── security-audit.yml       # Аудит безопасности
│   └── maintenance.yml          # Обслуживание
├── vulnerabilities/             # Плейбуки уязвимостей
│   ├── web-vulnerabilities.yml  # Веб уязвимости
│   ├── system-vulnerabilities.yml # Системные уязвимости
│   ├── network-vulnerabilities.yml # Сетевые уязвимости
│   └── database-vulnerabilities.yml # Уязвимости БД
├── scenarios/                   # Плейбуки сценариев
│   ├── scenario-1-unpatched.yml # Сценарий 1: Непатченная уязвимость
│   ├── scenario-2-misconfig.yml # Сценарий 2: Неправильная конфигурация
│   └── scenario-3-insider.yml   # Сценарий 3: Инсайдерская угроза
└── remediation/                 # Плейбуки устранения
    ├── patch-management.yml     # Управление патчами
    ├── config-fixes.yml         # Исправление конфигураций
    └── incident-response.yml    # Реагирование на инциденты
```

### Пример плейбука сценария (scenario-1-unpatched.yml)
```yaml
---
- name: "Сценарий 1: Развертывание уязвимого веб-сервера"
  hosts: web_servers
  become: yes
  vars:
    scenario_name: "unpatched-vulnerability"
    vulnerability_type: "web-application"
    target_version: "apache-2.4.29"  # Уязвимая версия
    exploit_cve: "CVE-2021-44228"    # Log4Shell
    
  pre_tasks:
    - name: "Обновление информации о пакетах"
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: "Обновление информации о пакетах"
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"
  
  roles:
    - role: common/system-update
      vars:
        install_security_updates: no  # Намеренно не устанавливаем патчи
        update_packages: no
    
    - role: web-server/apache
      vars:
        apache_version: "{{ target_version }}"
        apache_modules:
          - mod_rewrite
          - mod_ssl
          - mod_proxy
        apache_config:
          server_tokens: "Full"  # Небезопасная настройка
          server_signature: "On"  # Небезопасная настройка
          trace_enable: "On"      # Небезопасная настройка
    
    - role: vulnerabilities/web-vulnerabilities
      vars:
        install_vulnerable_apps: yes
        vulnerable_apps:
          - name: "log4j-demo"
            version: "2.14.1"  # Уязвимая версия Log4j
            port: 8080
            cve: "CVE-2021-44228"
    
    - role: monitoring/logging
      vars:
        log_level: "debug"  # Подробное логирование для обучения
        log_retention_days: 30
    
    - role: security/firewall
      vars:
        firewall_rules:
          - port: "80"
            protocol: "tcp"
            action: "allow"
            source: "any"
          - port: "443"
            protocol: "tcp"
            action: "allow"
            source: "any"
          - port: "8080"
            protocol: "tcp"
            action: "allow"
            source: "any"
  
  post_tasks:
    - name: "Создание тестовых пользователей"
      user:
        name: "{{ item.name }}"
        password: "{{ item.password | password_hash('sha512') }}"
        shell: /bin/bash
        groups: sudo
      loop:
        - { name: "admin", password: "admin123" }  # Слабый пароль
        - { name: "testuser", password: "password" }  # Слабый пароль
      vars:
        ansible_become: yes
    
    - name: "Настройка SSH для демонстрации уязвимостей"
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: "^#?PermitRootLogin", line: "PermitRootLogin yes" }
        - { regexp: "^#?PasswordAuthentication", line: "PasswordAuthentication yes" }
        - { regexp: "^#?PubkeyAuthentication", line: "PubkeyAuthentication yes" }
      notify: restart ssh
    
    - name: "Создание файлов с чувствительной информацией"
      copy:
        content: |
          Database credentials:
          Host: localhost
          User: root
          Password: root123
          Database: sensitive_data
        dest: "/home/admin/database_credentials.txt"
        owner: admin
        group: admin
        mode: '0644'
    
    - name: "Настройка cron для демонстрации"
      cron:
        name: "Backup script"
        minute: "0"
        hour: "2"
        job: "/bin/bash /home/admin/backup.sh"
        user: admin
    
    - name: "Создание скрипта резервного копирования"
      copy:
        content: |
          #!/bin/bash
          # Уязвимый скрипт резервного копирования
          mysqldump -u root -proot123 sensitive_data > /tmp/backup.sql
          chmod 777 /tmp/backup.sql
        dest: "/home/admin/backup.sh"
        owner: admin
        group: admin
        mode: '0755'
  
  handlers:
    - name: restart ssh
      service:
        name: ssh
        state: restarted
    
    - name: restart apache
      service:
        name: apache2
        state: restarted
      when: ansible_os_family == "Debian"
    
    - name: restart httpd
      service:
        name: httpd
        state: restarted
      when: ansible_os_family == "RedHat"
```

## Структура ролей (roles/)

```
roles/
├── common/                       # Общие роли
│   ├── system-update/            # Обновление системы
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── templates/
│   │   ├── files/
│   │   ├── vars/main.yml
│   │   ├── defaults/main.yml
│   │   ├── meta/main.yml
│   │   └── README.md
│   ├── user-management/          # Управление пользователями
│   ├── logging/                  # Настройка логирования
│   ├── time-sync/                # Синхронизация времени
│   └── package-management/       # Управление пакетами
├── web-server/                   # Веб-сервер
│   ├── apache/                   # Apache
│   ├── nginx/                    # Nginx
│   └── iis/                      # IIS
├── database/                     # База данных
│   ├── mysql/                    # MySQL
│   ├── postgresql/               # PostgreSQL
│   └── mongodb/                  # MongoDB
├── vulnerabilities/              # Роли уязвимостей
│   ├── web-vulnerabilities/       # Веб уязвимости
│   ├── system-vulnerabilities/   # Системные уязвимости
│   └── network-vulnerabilities/  # Сетевые уязвимости
├── security/                     # Безопасность
│   ├── firewall/                 # Брандмауэр
│   ├── ssl/                      # SSL/TLS
│   ├── antivirus/                # Антивирус
│   └── audit/                    # Аудит
└── monitoring/                   # Мониторинг
    ├── prometheus/               # Prometheus
    ├── grafana/                  # Grafana
    ├── elk/                      # ELK Stack
    └── zabbix/                   # Zabbix
```

### Пример роли web-server/apache
```
apache/
├── tasks/main.yml
├── handlers/main.yml
├── templates/
│   ├── apache2.conf.j2
│   ├── 000-default.conf.j2
│   └── ssl.conf.j2
├── files/
│   ├── apache2.service
│   └── index.html
├── vars/main.yml
├── defaults/main.yml
├── meta/main.yml
└── README.md
```

#### tasks/main.yml
```yaml
---
- name: "Установка Apache"
  package:
    name: "{{ apache_package_name }}"
    state: present
  when: ansible_os_family == "Debian"

- name: "Установка Apache"
  package:
    name: "{{ apache_package_name }}"
    state: present
  when: ansible_os_family == "RedHat"

- name: "Создание директории для конфигурации"
  file:
    path: "{{ apache_config_dir }}"
    state: directory
    mode: '0755'

- name: "Копирование основной конфигурации Apache"
  template:
    src: apache2.conf.j2
    dest: "{{ apache_config_file }}"
    backup: yes
    mode: '0644'
  notify: restart apache

- name: "Копирование конфигурации виртуального хоста"
  template:
    src: 000-default.conf.j2
    dest: "{{ apache_sites_available_dir }}/000-default.conf"
    backup: yes
    mode: '0644'
  notify: restart apache

- name: "Активация виртуального хоста"
  file:
    src: "{{ apache_sites_available_dir }}/000-default.conf"
    dest: "{{ apache_sites_enabled_dir }}/000-default.conf"
    state: link
  notify: restart apache

- name: "Создание директории для веб-контента"
  file:
    path: "{{ apache_document_root }}"
    state: directory
    mode: '0755'

- name: "Копирование тестовой страницы"
  copy:
    src: index.html
    dest: "{{ apache_document_root }}/index.html"
    mode: '0644'

- name: "Запуск и включение Apache"
  service:
    name: "{{ apache_service_name }}"
    state: started
    enabled: yes
```

#### handlers/main.yml
```yaml
---
- name: restart apache
  service:
    name: "{{ apache_service_name }}"
    state: restarted

- name: reload apache
  service:
    name: "{{ apache_service_name }}"
    state: reloaded
```

#### defaults/main.yml
```yaml
---
# Версия Apache
apache_version: "2.4"

# Имена пакетов для разных ОС
apache_package_name_debian: "apache2"
apache_package_name_redhat: "httpd"

# Пути конфигурации
apache_config_dir_debian: "/etc/apache2"
apache_config_dir_redhat: "/etc/httpd"

# Имена сервисов
apache_service_name_debian: "apache2"
apache_service_name_redhat: "httpd"

# Порты
apache_port: 80
apache_ssl_port: 443

# Директории
apache_document_root: "/var/www/html"
apache_log_dir: "/var/log/apache2"

# Модули
apache_modules:
  - mod_rewrite
  - mod_ssl
  - mod_proxy

# Настройки безопасности
apache_security_settings:
  server_tokens: "Prod"
  server_signature: "Off"
  trace_enable: "Off"
```

#### vars/main.yml
```yaml
---
# Определение переменных в зависимости от ОС
apache_package_name: "{{ apache_package_name_debian if ansible_os_family == 'Debian' else apache_package_name_redhat }}"
apache_config_dir: "{{ apache_config_dir_debian if ansible_os_family == 'Debian' else apache_config_dir_redhat }}"
apache_service_name: "{{ apache_service_name_debian if ansible_os_family == 'Debian' else apache_service_name_redhat }}"
apache_config_file: "{{ apache_config_dir }}/apache2.conf" if ansible_os_family == 'Debian' else "{{ apache_config_dir }}/conf/httpd.conf"
apache_sites_available_dir: "{{ apache_config_dir }}/sites-available"
apache_sites_enabled_dir: "{{ apache_config_dir }}/sites-enabled"
```

## Переменные групп (group_vars/)

### all.yml
```yaml
---
# Общие переменные для всех хостов
timezone: "UTC"
ntp_servers:
  - "pool.ntp.org"
  - "time.google.com"

# Настройки безопасности
security_settings:
  password_min_length: 8
  password_complexity: true
  session_timeout: 3600
  max_login_attempts: 3

# Настройки логирования
logging:
  level: "info"
  retention_days: 30
  max_size: "100MB"

# Настройки мониторинга
monitoring:
  enabled: true
  prometheus_port: 9090
  grafana_port: 3000
  alertmanager_port: 9093
```

### web_servers.yml
```yaml
---
# Переменные для веб-серверов
web_server_type: "apache"
http_port: 80
https_port: 443
ssl_enabled: true

# Настройки Apache
apache_config:
  server_tokens: "Prod"
  server_signature: "Off"
  trace_enable: "Off"
  keepalive: "On"
  max_keepalive_requests: 100

# Настройки SSL
ssl_config:
  ssl_protocol: "TLSv1.2 TLSv1.3"
  ssl_cipher_suite: "HIGH:!aNULL:!MD5"
  ssl_honor_cipher_order: "On"
```

## Ansible Vault (vault/)

### secrets.yml
```yaml
---
# Основные секреты
vault_mysql_root_password: "SecureRootPassword123!"
vault_postgres_password: "SecurePostgresPassword123!"
vault_admin_password: "SecureAdminPassword123!"

# API ключи
vault_prometheus_api_key: "prometheus-api-key-here"
vault_grafana_api_key: "grafana-api-key-here"

# Сертификаты
vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  [PRIVATE KEY CONTENT]
  -----END PRIVATE KEY-----

vault_ssl_certificate: |
  -----BEGIN CERTIFICATE-----
  [CERTIFICATE CONTENT]
  -----END CERTIFICATE-----
```

## Скрипты (scripts/)

### deploy-scenario.sh
```bash
#!/bin/bash
# Скрипт развертывания сценария

set -e

SCENARIO_NAME=$1
INVENTORY_FILE=$2
VAULT_PASSWORD_FILE=$3

if [ -z "$SCENARIO_NAME" ] || [ -z "$INVENTORY_FILE" ] || [ -z "$VAULT_PASSWORD_FILE" ]; then
    echo "Использование: $0 <scenario_name> <inventory_file> <vault_password_file>"
    echo "Пример: $0 scenario-1 inventories/production/hosts.yml ~/.vault_pass"
    exit 1
fi

echo "Развертывание сценария: $SCENARIO_NAME"
echo "Инвентарь: $INVENTORY_FILE"
echo "Vault пароль: $VAULT_PASSWORD_FILE"

# Проверка существования файлов
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "Ошибка: Файл инвентаря $INVENTORY_FILE не найден"
    exit 1
fi

if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
    echo "Ошибка: Файл пароля vault $VAULT_PASSWORD_FILE не найден"
    exit 1
fi

# Запуск плейбука сценария
ansible-playbook \
    -i "$INVENTORY_FILE" \
    --vault-password-file "$VAULT_PASSWORD_FILE" \
    --extra-vars "scenario_name=$SCENARIO_NAME" \
    "playbooks/scenarios/scenario-${SCENARIO_NAME}.yml"

echo "Сценарий $SCENARIO_NAME успешно развернут"
```

## Лучшие практики

1. **Модульность**: Используйте роли для переиспользования логики
2. **Безопасность**: Храните секреты в Ansible Vault
3. **Документация**: Документируйте все роли и плейбуки
4. **Тестирование**: Используйте Molecule для тестирования ролей
5. **Версионирование**: Используйте теги для версионирования
6. **Идемпотентность**: Плейбуки должны быть идемпотентными
7. **Обработка ошибок**: Используйте блоки rescue для обработки ошибок
8. **Производительность**: Оптимизируйте количество задач и используйте кэширование

Эта структура обеспечивает эффективное управление конфигурациями учебных сценариев с помощью Ansible.
