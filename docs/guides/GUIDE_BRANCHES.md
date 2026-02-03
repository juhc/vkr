# Руководство по работе со сценариями в разных ветках

## Быстрый старт

### Просмотр доступных веток

```bash
# Показать все локальные ветки
git branch

# Показать все ветки (включая удаленные)
git branch -a

# Показать текущую ветку
git branch --show-current
```

### Переключение между ветками

```bash
# Переключиться на ветку ISP-компании
git checkout scenario-isp-company

# Переключиться на ветку офисной организации
git checkout scenario-office-organization

# Вернуться на основную ветку
git checkout main
```

## Работа с конкретным сценарием

### 1. Сценарий ISP-компании

#### Переключение и навигация

```bash
# Переключиться на ветку
git checkout scenario-isp-company

# Перейти в директорию сценария
cd stands/windows-stand

# Просмотреть структуру
ls -la
```

#### Структура файлов

```
stands/windows-stand/
├── README.md              # Описание сценария
├── QUICKSTART.md          # Быстрый старт
├── DEPLOYMENT.md          # Инструкции по развертыванию
├── network-topology.md    # Сетевая топология
├── machine-scenarios.md  # Описание машин
└── objectives.md          # Цели обучения
```

#### Внесение изменений

```bash
# 1. Убедитесь, что вы на правильной ветке
git checkout scenario-isp-company

# 2. Внесите изменения в файлы
# Например, отредактируйте README.md
nano stands/windows-stand/README.md

# 3. Проверьте изменения
git status
git diff

# 4. Добавьте изменения
git add stands/windows-stand/README.md

# 5. Закоммитьте
git commit -m "Обновлен README для ISP сценария"

# 6. Опубликуйте изменения
git push origin scenario-isp-company
```

### 2. Сценарий офисной организации

#### Переключение и навигация

```bash
# Переключиться на ветку
git checkout scenario-office-organization

# Перейти в директорию сценария
cd stands/linux-stand

# Просмотреть структуру
ls -la
```

#### Структура файлов

```
stands/linux-stand/
├── README.md
├── QUICKSTART.md
├── DEPLOYMENT.md
├── network-topology.md
├── machine-scenarios.md
├── objectives.md
├── infrastructure/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── ansible/
│       ├── playbook.yml
│       └── inventory.yml
└── scripts/
    ├── deploy.sh
    └── destroy.sh
```

#### Внесение изменений

```bash
# 1. Переключитесь на ветку
git checkout scenario-office-organization

# 2. Внесите изменения
# Например, измените Terraform конфигурацию
nano stands/linux-stand/infrastructure/terraform/linux-server/main.tf

# 3. Проверьте изменения
git status
git diff

# 4. Добавьте и закоммитьте
git add stands/linux-stand/infrastructure/terraform/linux-server/main.tf
git commit -m "Обновлена Terraform конфигурация"

# 5. Опубликуйте
git push origin scenario-office-organization
```

## Работа с общими компонентами

### Обновление Terraform модулей

Общие Terraform модули находятся в `terraform/modules/`. При их изменении нужно синхронизировать изменения во все ветки.

#### Шаг 1: Обновление в main

```bash
# Переключитесь на main
git checkout main

# Внесите изменения в модули
nano terraform/modules/vm/main.tf

# Закоммитьте
git add terraform/modules/
git commit -m "Обновлен модуль VM"
git push origin main
```

#### Шаг 2: Синхронизация с ветками сценариев

```bash
# Синхронизация с ISP-сценарием
git checkout scenario-isp-company
git merge main
# Разрешите конфликты, если они возникнут
git push origin scenario-isp-company

# Синхронизация с офисным сценарием
git checkout scenario-office-organization
git merge main
# Разрешите конфликты, если они возникнут
git push origin scenario-office-organization
```

### Обновление Ansible ролей

Аналогично Terraform модулям:

```bash
# 1. Обновите в main
git checkout main
nano ansible/roles/vkr_vuln_linux/tasks/main.yml
git add ansible/roles/
git commit -m "Обновлены роли Ansible"
git push origin main

# 2. Синхронизируйте с ветками
git checkout scenario-isp-company
git merge main
git push origin scenario-isp-company

git checkout scenario-office-organization
git merge main
git push origin scenario-office-organization
```

## Типичные рабочие процессы

### Сценарий 1: Добавление нового файла в сценарий

```bash
# 1. Переключитесь на нужную ветку
git checkout scenario-isp-company

# 2. Создайте новый файл
nano stands/windows-stand/NEW_FILE.md

# 3. Добавьте и закоммитьте
git add stands/windows-stand/NEW_FILE.md
git commit -m "Добавлен новый файл в ISP сценарий"

# 4. Опубликуйте
git push origin scenario-isp-company
```

### Сценарий 2: Изменение документации сценария

```bash
# 1. Переключитесь на ветку
git checkout scenario-office-organization

# 2. Отредактируйте файл
nano stands/linux-stand/README.md

# 3. Проверьте изменения
git diff stands/linux-stand/README.md

# 4. Закоммитьте
git add stands/linux-stand/README.md
git commit -m "Обновлена документация офисного сценария"

# 5. Опубликуйте
git push origin scenario-office-organization
```

### Сценарий 3: Изменение Terraform конфигурации сценария

```bash
# 1. Переключитесь на ветку
git checkout scenario-office-organization

# 2. Измените конфигурацию
nano stands/linux-stand/infrastructure/terraform/linux-server/main.tf

# 3. Проверьте синтаксис (если установлен terraform)
cd stands/linux-stand/infrastructure/terraform/linux-server
terraform fmt
terraform validate

# 4. Вернитесь в корень и закоммитьте
cd ../../../../..
git add stands/linux-stand/infrastructure/terraform/
git commit -m "Обновлена Terraform конфигурация"

# 5. Опубликуйте
git push origin scenario-office-organization
```

### Сценарий 4: Изменение Ansible плейбука

```bash
# 1. Переключитесь на ветку
git checkout scenario-office-organization

# 2. Измените плейбук
nano stands/linux-stand/infrastructure/ansible/linux-server/playbook.yml

# 3. Проверьте синтаксис (если установлен ansible-lint)
ansible-lint stands/linux-stand/infrastructure/ansible/linux-server/playbook.yml

# 4. Закоммитьте
git add stands/linux-stand/infrastructure/ansible/
git commit -m "Обновлен Ansible плейбук"

# 5. Опубликуйте
git push origin scenario-office-organization
```

## Разрешение конфликтов

При слиянии изменений из main в ветки сценариев могут возникнуть конфликты.

### Процесс разрешения конфликтов

```bash
# 1. Переключитесь на ветку сценария
git checkout scenario-isp-company

# 2. Попытайтесь слить изменения из main
git merge main

# 3. Если есть конфликты, Git сообщит:
# Auto-merging <file>
# CONFLICT (content): Merge conflict in <file>

# 4. Откройте файл с конфликтом
nano <file>

# 5. Найдите маркеры конфликта:
# <<<<<<< HEAD
# (ваши изменения)
# =======
# (изменения из main)
# >>>>>>> main

# 6. Решите конфликт:
# - Оставьте нужные изменения
# - Удалите маркеры конфликта
# - Сохраните файл

# 7. Добавьте разрешенный файл
git add <file>

# 8. Завершите слияние
git commit -m "Разрешен конфликт при слиянии с main"
```

## Полезные команды Git

### Просмотр истории изменений

```bash
# История текущей ветки
git log --oneline

# История конкретного файла
git log --oneline stands/windows-stand/README.md

# Графическое представление всех веток
git log --oneline --graph --all

# Показать изменения в файле
git diff HEAD stands/windows-stand/README.md
```

### Отмена изменений

```bash
# Отменить изменения в рабочей директории (не закоммиченные)
git checkout -- <file>

# Отменить последний коммит (сохранить изменения)
git reset --soft HEAD~1

# Отменить последний коммит (удалить изменения)
git reset --hard HEAD~1
```

### Создание новой ветки для разработки

```bash
# Создать новую ветку из текущей
git checkout -b feature/new-feature

# Создать новую ветку из main
git checkout main
git checkout -b feature/new-feature

# Опубликовать новую ветку
git push origin feature/new-feature
```

## Работа с удаленным репозиторием

### Получение последних изменений

```bash
# Получить информацию об удаленных ветках
git fetch origin

# Обновить текущую ветку
git pull origin scenario-isp-company

# Обновить все ветки
git fetch --all
```

### Публикация изменений

```bash
# Опубликовать текущую ветку
git push origin scenario-isp-company

# Опубликовать и установить отслеживание
git push -u origin scenario-isp-company

# Опубликовать все ветки
git push --all origin
```

## Рекомендации

### ✅ Хорошие практики

1. **Всегда проверяйте текущую ветку** перед внесением изменений:
   ```bash
   git branch --show-current
   ```

2. **Коммитьте часто** с понятными сообщениями:
   ```bash
   git commit -m "Описание изменений"
   ```

3. **Синхронизируйте изменения** из main регулярно:
   ```bash
   git checkout scenario-isp-company
   git merge main
   ```

4. **Проверяйте изменения** перед коммитом:
   ```bash
   git status
   git diff
   ```

5. **Тестируйте изменения** перед публикацией:
   ```bash
   # Для Terraform
   terraform validate
   
   # Для Ansible
   ansible-lint playbook.yml
   ```

### ❌ Чего избегать

1. **Не коммитьте в неправильную ветку** - всегда проверяйте текущую ветку
2. **Не игнорируйте конфликты** - разрешайте их сразу
3. **Не коммитьте чувствительные данные**: храните их локально/в менеджере секретов (Ansible Vault — опционально)
4. **Не забывайте синхронизировать** - регулярно мержите изменения из main
5. **Не публикуйте без проверки** - тестируйте изменения перед push

## Примеры полных рабочих процессов

### Пример 1: Добавление новой машины в ISP-сценарий

```bash
# 1. Переключитесь на ветку
git checkout scenario-isp-company

# 2. Обновите документацию
nano stands/windows-stand/machine-scenarios.md
# Добавьте описание новой машины

# 3. Обновите сетевую топологию
nano stands/windows-stand/network-topology.md
# Добавьте новую машину в топологию

# 4. Проверьте изменения
git status
git diff

# 5. Закоммитьте
git add stands/windows-stand/
git commit -m "Добавлена новая машина в ISP сценарий"

# 6. Опубликуйте
git push origin scenario-isp-company
```

### Пример 2: Обновление общей роли Ansible

```bash
# 1. Обновите в main
git checkout main
nano ansible/roles/vkr_accounts/tasks/linux.yml
git add ansible/roles/vkr_accounts/
git commit -m "Обновлена роль vkr_accounts"
git push origin main

# 2. Синхронизируйте с ISP-сценарием
git checkout scenario-isp-company
git merge main
git push origin scenario-isp-company

# 3. Синхронизируйте с офисным сценарием
git checkout scenario-office-organization
git merge main
git push origin scenario-office-organization

# 4. Вернитесь на main
git checkout main
```

## Получение помощи

### Полезные команды Git

```bash
# Справка по команде
git help <command>

# Например:
git help checkout
git help merge
git help push
```

### Просмотр статуса

```bash
# Текущий статус
git status

# Краткий статус
git status -s

# Статус с игнорируемыми файлами
git status --ignored
```

## Заключение

Работа со сценариями в разных ветках требует:
1. Понимания текущей ветки
2. Правильного переключения между ветками
3. Регулярной синхронизации общих компонентов
4. Внимательности при разрешении конфликтов

Следуйте этим рекомендациям, и работа с проектом будет эффективной и безопасной.

