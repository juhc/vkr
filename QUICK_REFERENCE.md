# Быстрая справка: Работа со сценариями в ветках

## 🔄 Переключение между ветками

```bash
# Показать все ветки
git branch

# Переключиться на ветку
git checkout scenario-isp-company
git checkout scenario-office-organization
git checkout main

# Показать текущую ветку
git branch --show-current
```

## 📝 Внесение изменений

### Изменение файлов сценария

```bash
# 1. Переключитесь на нужную ветку
git checkout scenario-isp-company

# 2. Внесите изменения
nano scenarios/scenario-isp-company/README.md

# 3. Проверьте изменения
git status
git diff

# 4. Закоммитьте
git add scenarios/scenario-isp-company/README.md
git commit -m "Описание изменений"

# 5. Опубликуйте
git push origin scenario-isp-company
```

### Изменение общих компонентов

```bash
# 1. Обновите в main
git checkout main
nano terraform/modules/vm/main.tf
git add terraform/modules/
git commit -m "Обновлен модуль VM"
git push origin main

# 2. Синхронизируйте с ветками
git checkout scenario-isp-company
git merge main
git push origin scenario-isp-company

git checkout scenario-office-organization
git merge main
git push origin scenario-office-organization
```

## 📂 Структура сценариев

### ISP-компания
```
scenarios/scenario-isp-company/
├── README.md
├── QUICKSTART.md
├── DEPLOYMENT.md
├── network-topology.md
├── machine-scenarios.md
└── objectives.md
```

### Офисная организация
```
scenarios/scenario-office-organization/
├── README.md
├── QUICKSTART.md
├── DEPLOYMENT.md
├── network-topology.md
├── machine-scenarios.md
├── objectives.md
├── infrastructure/
│   ├── terraform/
│   └── ansible/
└── scripts/
```

## 🔍 Полезные команды

```bash
# История изменений
git log --oneline

# История конкретного файла
git log --oneline scenarios/scenario-isp-company/README.md

# График всех веток
git log --oneline --graph --all

# Отменить незакоммиченные изменения
git checkout -- <file>

# Получить последние изменения
git pull origin scenario-isp-company
```

## ⚠️ Разрешение конфликтов

```bash
# При слиянии из main
git checkout scenario-isp-company
git merge main

# Если есть конфликты:
# 1. Откройте файл с конфликтом
nano <file>

# 2. Найдите и разрешите конфликты:
# <<<<<<< HEAD
# (ваши изменения)
# =======
# (изменения из main)
# >>>>>>> main

# 3. Сохраните и добавьте файл
git add <file>
git commit -m "Разрешен конфликт"
```

## 📚 Дополнительная документация

- [GUIDE_BRANCHES.md](GUIDE_BRANCHES.md) - Подробное руководство
- [BRANCHES.md](BRANCHES.md) - Структура веток
- [ANALYSIS_BRANCHES.md](ANALYSIS_BRANCHES.md) - Анализ подхода

