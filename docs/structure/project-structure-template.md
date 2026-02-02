# Шаблон структуры репозитория проекта киберучений по защите ОС

## Общая структура репозитория

```
cyber-range-lab/
├── README.md                           # Основная документация проекта
├── LICENSE                             # Лицензия проекта
├── .gitignore                          # Исключения для Git
├── .gitattributes                      # Настройки Git
├── requirements.txt                    # Python зависимости (если нужны)
├── Makefile                           # Автоматизация команд
│
├── docs/                              # Документация проекта
│   ├── README.md                      # Индекс документации
│   ├── admin-guide/                   # Руководство администратора
│   │   ├── installation.md           # Установка и настройка
│   │   ├── configuration.md          # Конфигурация системы
│   │   └── troubleshooting.md        # Решение проблем
│   ├── instructor-guide/              # Методические указания для преподавателя
│   │   ├── scenario-overview.md       # Обзор сценариев
│   │   ├── grading-criteria.md       # Критерии оценки
│   │   └── best-practices.md         # Лучшие практики
│   ├── student-guide/                 # Инструкции для студентов
│   │   ├── getting-started.md        # Начало работы
│   │   ├── tools-and-techniques.md   # Инструменты и техники
│   │   └── reporting-template.md     # Шаблон отчета
│   └── architecture/                 # Архитектурная документация
│       ├── system-design.md          # Дизайн системы
│       ├── security-model.md         # Модель безопасности
│       └── deployment-flow.md        # Процесс развертывания
│
├── terraform/                         # Terraform конфигурации
│   ├── modules/                      # Переиспользуемые модули
│   │   ├── vm/                       # Модуль виртуальных машин
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── versions.tf
│   │   ├── network/                  # Модуль сетей
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── versions.tf
│   │   ├── security/                 # Модуль безопасности
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── versions.tf
│   │   └── monitoring/               # Модуль мониторинга
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── versions.tf
│   ├── environments/                  # Конфигурации окружений
│   │   ├── development/              # Разработка
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── outputs.tf
│   │   ├── staging/                  # Тестирование
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── outputs.tf
│   │   └── production/               # Продакшн
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       └── outputs.tf
│   ├── shared/                       # Общие ресурсы
│   │   ├── providers.tf              # Провайдеры
│   │   ├── backend.tf                # Backend конфигурация
│   │   └── variables.tf              # Общие переменные
│   └── scripts/                      # Скрипты для Terraform
│       ├── init.sh                   # Инициализация
│       ├── deploy.sh                 # Развертывание
│       └── destroy.sh                # Удаление
│
├── ansible/                          # Ansible конфигурации
│   ├── playbooks/                    # Плейбуки
│   │   ├── common/                   # Общие плейбуки
│   │   │   ├── system-hardening.yml  # Усиление системы
│   │   │   ├── monitoring-setup.yml  # Настройка мониторинга
│   │   │   └── backup-config.yml    # Настройка резервного копирования
│   │   ├── vulnerabilities/          # Плейбуки уязвимостей
│   │   │   ├── web-vulnerabilities.yml
│   │   │   ├── system-vulnerabilities.yml
│   │   │   └── network-vulnerabilities.yml
│   │   └── stands/                   # Плейбуки стендов
│   │       ├── scenario-1.yml
│   │       ├── scenario-2.yml
│   │       └── scenario-3.yml
│   ├── roles/                       # Роли Ansible
│   │   ├── common/                  # Общие роли
│   │   │   ├── system-update/       # Обновление системы
│   │   │   ├── user-management/     # Управление пользователями
│   │   │   └── logging/             # Настройка логирования
│   │   ├── web-server/              # Веб-сервер
│   │   │   ├── tasks/main.yml
│   │   │   ├── handlers/main.yml
│   │   │   ├── (опционально) шаблоны/
│   │   │   ├── files/
│   │   │   └── vars/main.yml
│   │   ├── database/                # База данных
│   │   │   ├── tasks/main.yml
│   │   │   ├── handlers/main.yml
│   │   │   ├── (опционально) шаблоны/
│   │   │   ├── files/
│   │   │   └── vars/main.yml
│   │   ├── firewall/                # Брандмауэр
│   │   │   ├── tasks/main.yml
│   │   │   ├── handlers/main.yml
│   │   │   ├── (опционально) шаблоны/
│   │   │   ├── files/
│   │   │   └── vars/main.yml
│   │   └── monitoring/              # Мониторинг
│   │       ├── tasks/main.yml
│   │       ├── handlers/main.yml
│   │       ├── (опционально) шаблоны/
│   │       ├── files/
│   │       └── vars/main.yml
│   ├── inventories/                 # Инвентари
│   │   ├── production/              # Продакшн инвентарь
│   │   │   ├── hosts.yml
│   │   │   └── group_vars/
│   │   ├── staging/                 # Тестовый инвентарь
│   │   │   ├── hosts.yml
│   │   │   └── group_vars/
│   │   └── development/             # Инвентарь разработки
│   │       ├── hosts.yml
│   │       └── group_vars/
│   ├── group_vars/                  # Переменные групп
│   │   ├── all.yml                  # Общие переменные
│   │   ├── web-servers.yml          # Переменные веб-серверов
│   │   ├── databases.yml            # Переменные БД
│   │   └── monitoring.yml           # Переменные мониторинга
│   ├── host_vars/                   # Переменные хостов
│   │   ├── web-server-01.yml
│   │   ├── database-01.yml
│   │   └── monitoring-01.yml
│   ├── ansible.cfg                  # Конфигурация Ansible
│   └── vault/                       # Ansible Vault файлы
│       ├── secrets.yml              # Секреты
│       └── passwords.yml            # Пароли
│
├── stands/                           # Учебные стенды
│   ├── scenario-1-unpatched-vulnerability/  # Сценарий 1: Непатченная уязвимость
│   │   ├── README.md                # Главная навигация сценария
│   │   ├── docs/                    # Документация сценария
│   │   │   ├── README.md            # Индекс документации
│   │   │   ├── overview/            # Обзор сценария
│   │   │   │   ├── README.md        # Описание организации/сценария
│   │   │   │   ├── network-topology.md # Сетевая топология
│   │   │   │   └── machine-scenarios.md # Описание машин и уязвимостей
│   │   │   ├── deployment/          # Развертывание
│   │   │   │   ├── QUICKSTART.md    # Быстрый старт
│   │   │   │   ├── QUICK_TEST_DEPLOY.md # Тестовое развертывание
│   │   │   │   └── DEPLOYMENT.md    # Полное руководство
│   │   │   ├── learning/            # Обучение
│   │   │   │   └── objectives.md    # Цели обучения
│   │   │   └── assessment/          # Оценка
│   │   │       ├── CHECKLISTS.md    # Чек-листы для проверки
│   │   │       ├── REPORT_TEMPLATE.md # Шаблон отчета
│   │   │       └── SOLUTIONS.md     # Решения (только для преподавателей)
│   │   ├── infrastructure/          # Инфраструктура сценария
│   │   │   ├── terraform/           # Terraform конфигурации
│   │   │   └── ansible/             # Ansible конфигурации
│   │   ├── exercises/               # Упражнения (опционально, можно в docs/)
│   │   │   ├── detection.md         # Обнаружение уязвимости
│   │   │   ├── exploitation.md      # Эксплуатация
│   │   │   └── remediation.md       # Устранение
│   │   ├── solutions/               # Решения (опционально, можно в docs/assessment/)
│   │   │   ├── detection-solution.md
│   │   │   ├── exploitation-solution.md
│   │   │   └── remediation-solution.md
│   │   └── resources/               # Ресурсы
│   │       ├── scripts/             # Скрипты
│   │       ├── tools/               # Инструменты
│   │       └── references/          # Ссылки
│   ├── scenario-2-misconfiguration/ # Сценарий 2: Неправильная конфигурация
│   │   ├── README.md
│   │   ├── objectives.md
│   │   ├── infrastructure/
│   │   ├── exercises/
│   │   ├── solutions/
│   │   └── resources/
│   └── scenario-3-insider-threat/   # Сценарий 3: Инсайдерская угроза
│       ├── README.md
│       ├── objectives.md
│       ├── infrastructure/
│       ├── exercises/
│       ├── solutions/
│       └── resources/
│
├── tools/                           # Инструменты и утилиты
│   ├── deployment/                  # Инструменты развертывания
│   │   ├── deploy-lab.sh           # Развертывание лаборатории
│   │   ├── cleanup-lab.sh          # Очистка лаборатории
│   │   └── reset-scenario.sh       # Сброс сценария
│   ├── monitoring/                 # Инструменты мониторинга
│   │   ├── log-collector.sh        # Сбор логов
│   │   ├── metrics-gatherer.py     # Сбор метрик
│   │   └── alert-manager.yml       # Управление алертами
│   ├── security/                   # Инструменты безопасности
│   │   ├── vulnerability-scanner.py
│   │   ├── compliance-checker.sh
│   │   └── security-audit.yml
│   └── utilities/                  # Утилиты
│       ├── backup-tools/
│       ├── network-tools/
│       └── system-tools/
│
├── tests/                          # Тесты
│   ├── terraform/                  # Тесты Terraform
│   │   ├── unit/                   # Модульные тесты
│   │   ├── integration/            # Интеграционные тесты
│   │   └── security/               # Тесты безопасности
│   ├── ansible/                    # Тесты Ansible
│   │   ├── molecule/              # Molecule тесты
│   │   ├── lint/                   # Линтеры
│   │   └── security/               # Тесты безопасности
│   ├── stands/                     # Тесты стендов
│   │   ├── functional/             # Функциональные тесты
│   │   ├── performance/            # Тесты производительности
│   │   └── security/               # Тесты безопасности
│   └── e2e/                        # End-to-end тесты
│       ├── deployment/             # Тесты развертывания
│       ├── stands/                 # Тесты стендов
│       └── cleanup/                # Тесты очистки
│
├── .github/                        # GitHub Actions
│   ├── workflows/                  # Workflow файлы
│   │   ├── terraform-lint.yml      # Линтинг Terraform
│   │   ├── ansible-lint.yml        # Линтинг Ansible
│   │   ├── security-scan.yml       # Сканирование безопасности
│   │   ├── deployment-test.yml     # Тестирование развертывания
│   │   └── scenario-test.yml       # Тестирование сценариев
│   ├── ISSUE_TEMPLATE/             # Шаблоны issues
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── scenario_request.md
│   └── PULL_REQUEST_TEMPLATE.md    # Шаблон pull request
│
├── scripts/                        # Скрипты автоматизации
│   ├── setup/                      # Скрипты настройки
│   │   ├── install-dependencies.sh # Установка зависимостей
│   │   ├── configure-environment.sh # Настройка окружения
│   │   └── setup-git-hooks.sh      # Настройка Git hooks
│   ├── deployment/                 # Скрипты развертывания
│   │   ├── deploy-all.sh          # Развертывание всего
│   │   ├── deploy-scenario.sh      # Развертывание сценария
│   │   └── rollback.sh            # Откат изменений
│   ├── maintenance/                # Скрипты обслуживания
│   │   ├── backup.sh              # Резервное копирование
│   │   ├── cleanup.sh             # Очистка
│   │   └── health-check.sh        # Проверка здоровья
│   └── development/               # Скрипты разработки
│       ├── new-scenario.sh         # Создание нового сценария
│       ├── validate-config.sh      # Валидация конфигурации
│       └── generate-docs.sh       # Генерация документации
│
├── config/                         # Конфигурационные файлы
│   ├── terraform/                  # Конфигурации Terraform
│   │   ├── terraform.tf           # Основная конфигурация
│   │   ├── providers.tf           # Провайдеры
│   │   └── backend.tf             # Backend
│   ├── ansible/                    # Конфигурации Ansible
│   │   ├── ansible.cfg            # Основная конфигурация
│   │   └── inventory/             # Инвентари
│   ├── monitoring/                # Конфигурации мониторинга
│   │   ├── prometheus.yml         # Prometheus
│   │   ├── grafana/               # Grafana
│   │   └── alertmanager.yml       # Alertmanager
│   └── security/                  # Конфигурации безопасности
│       ├── fail2ban/              # Fail2ban
│       ├── auditd/                # Auditd
│       └── selinux/               # SELinux
│
├── data/                          # Данные и ресурсы
│   ├── os-images/                 # Образы ОС
│   │   ├── ubuntu/
│   │   ├── centos/
│   │   └── windows/
│   ├── vulnerability-db/          # База данных уязвимостей
│   │   ├── cve-list.json
│   │   ├── exploit-db.json
│   │   └── patch-info.json
│   ├── logs/                      # Логи (если нужны)
│   └── backups/                   # Резервные копии
│
└── (опционально) шаблоны/         # Шаблоны (если нужны)
    ├── scenario-template/         # Шаблон сценария
    │   ├── README.md.template
    │   ├── infrastructure/
    │   ├── exercises/
    │   └── resources/
    ├── terraform-module-template/ # Шаблон модуля Terraform
    ├── ansible-role-template/      # Шаблон роли Ansible
    └── documentation-template/     # Шаблон документации
```

## Описание основных компонентов

### 1. Корневая структура
- **README.md** - Основная документация проекта с описанием целей, архитектуры и инструкций по использованию
- **LICENSE** - Лицензия проекта
- **Makefile** - Автоматизация часто используемых команд
- **requirements.txt** - Python зависимости для инструментов

### 2. Документация (docs/)
Структурированная документация для разных ролей:
- **admin-guide/** - Руководство для администраторов системы
- **instructor-guide/** - Методические материалы для преподавателей
- **student-guide/** - Инструкции для студентов
- **architecture/** - Техническая документация архитектуры

### 3. Terraform (terraform/)
- **modules/** - Переиспользуемые модули для создания инфраструктуры
- **environments/** - Конфигурации для разных окружений
- **shared/** - Общие ресурсы и конфигурации
- **scripts/** - Скрипты для автоматизации работы с Terraform

### 4. Ansible (ansible/)
- **playbooks/** - Плейбуки для настройки систем
- **roles/** - Роли для переиспользования логики
- **inventories/** - Инвентари для разных окружений
- **vault/** - Зашифрованные секреты

### 5. Стенды (stands/)
Каждый сценарий содержит:
- **README.md** - главная навигация сценария
- **docs/** - структурированная документация:
  - **overview/** - обзор сценария (описание, сеть, машины)
  - **deployment/** - руководства по развертыванию
  - **learning/** - цели обучения
  - **assessment/** - чек-листы, шаблоны отчетов, решения
- **infrastructure/** - инфраструктурные конфигурации (Terraform, Ansible)
- **exercises/** - упражнения для студентов (опционально)
- **solutions/** - решения для преподавателей (опционально, можно в docs/assessment/)
- **resources/** - дополнительные ресурсы (скрипты, инструменты, ссылки)

### 6. Инструменты (tools/)
- **deployment/** - Инструменты развертывания
- **monitoring/** - Инструменты мониторинга
- **security/** - Инструменты безопасности
- **utilities/** - Вспомогательные утилиты

### 7. Тесты (tests/)
Комплексное тестирование всех компонентов:
- Тесты Terraform конфигураций
- Тесты Ansible плейбуков
- Тесты сценариев
- End-to-end тесты

### 8. CI/CD (.github/)
Автоматизация процессов разработки:
- Линтинг кода
- Сканирование безопасности
- Тестирование развертывания
- Шаблоны для issues и PR

### 9. Скрипты (scripts/)
Автоматизация рутинных операций:
- Настройка окружения
- Развертывание инфраструктуры
- Обслуживание системы
- Разработка

### 10. Конфигурации (config/)
Централизованное хранение конфигураций:
- Terraform конфигурации
- Ansible конфигурации
- Настройки мониторинга
- Конфигурации безопасности

### 11. Данные (data/)
Статические ресурсы:
- Образы операционных систем
- База данных уязвимостей
- Логи и резервные копии

### 12. Шаблоны (опционально)
Шаблоны для быстрого создания новых компонентов:
- Шаблон сценария
- Шаблон модуля Terraform
- Шаблон роли Ansible
- Шаблон документации

## Принципы организации

1. **Модульность** - Каждый компонент изолирован и может быть переиспользован
2. **Версионирование** - Все изменения отслеживаются через Git
3. **Документированность** - Каждый компонент имеет соответствующую документацию
4. **Тестируемость** - Все компоненты покрыты тестами
5. **Безопасность** - Секреты хранятся в зашифрованном виде
6. **Автоматизация** - Максимальная автоматизация рутинных операций
7. **Масштабируемость** - Структура позволяет легко добавлять новые сценарии и компоненты

## Использование шаблона

1. Скопируйте структуру в новый репозиторий
2. Заполните основные файлы (README.md, LICENSE)
3. Настройте конфигурации под ваши требования
4. Создайте первый сценарий на основе шаблона
5. Настройте CI/CD pipeline
6. Добавьте документацию для вашего конкретного случая

Эта структура обеспечивает профессиональную организацию проекта киберучений, соответствующую современным практикам DevOps и DevSecOps.
