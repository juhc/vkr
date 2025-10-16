# Структура CI/CD и автоматизации для проекта киберучений

## Обзор CI/CD структуры

Система непрерывной интеграции и развертывания (CI/CD) обеспечивает автоматизацию процессов разработки, тестирования и развертывания платформы киберучений.

## Структура CI/CD (.github/)

```
.github/
├── workflows/                          # GitHub Actions workflows
│   ├── terraform-lint.yml             # Линтинг Terraform кода
│   ├── ansible-lint.yml               # Линтинг Ansible кода
│   ├── security-scan.yml              # Сканирование безопасности
│   ├── deployment-test.yml            # Тестирование развертывания
│   ├── scenario-test.yml              # Тестирование сценариев
│   ├── documentation-build.yml        # Сборка документации
│   ├── release.yml                    # Релиз
│   └── cleanup.yml                     # Очистка ресурсов
├── ISSUE_TEMPLATE/                     # Шаблоны issues
│   ├── bug_report.md                   # Шаблон отчета об ошибке
│   ├── feature_request.md              # Шаблон запроса функции
│   ├── scenario_request.md             # Шаблон запроса сценария
│   └── security_issue.md               # Шаблон отчета о безопасности
├── PULL_REQUEST_TEMPLATE.md            # Шаблон pull request
├── dependabot.yml                      # Конфигурация Dependabot
├── CODEOWNERS                          # Владельцы кода
└── FUNDING.yml                         # Информация о финансировании
```

## GitHub Actions Workflows

### terraform-lint.yml
```yaml
name: Terraform Lint

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-lint.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'terraform/**'

jobs:
  terraform-lint:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
        
    - name: Terraform Format Check
      id: fmt
      run: terraform fmt -check -recursive terraform/
      continue-on-error: true
      
    - name: Terraform Init
      run: |
        cd terraform/environments/development
        terraform init -backend=false
        
    - name: Terraform Validate
      run: |
        cd terraform/environments/development
        terraform validate
        
    - name: Terraform Security Scan
      uses: aquasecurity/tfsec-action@v1.0.3
      with:
        working_directory: terraform/
        
    - name: Terraform Cost Estimation
      uses: dorny/paths-filter@v2
      if: github.event_name == 'pull_request'
      with:
        filters: |
          terraform:
            - 'terraform/**'
            
    - name: Comment PR with Cost Estimation
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const costFile = 'terraform-cost.txt';
          if (fs.existsSync(costFile)) {
            const cost = fs.readFileSync(costFile, 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 💰 Terraform Cost Estimation\n\n\`\`\`\n${cost}\n\`\`\``
            });
          }
```

### ansible-lint.yml
```yaml
name: Ansible Lint

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'ansible/**'
      - '.github/workflows/ansible-lint.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'ansible/**'

jobs:
  ansible-lint:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        
    - name: Install Ansible and dependencies
      run: |
        pip install ansible ansible-lint molecule
        ansible-galaxy collection install community.general
        
    - name: Ansible Lint
      run: |
        ansible-lint ansible/playbooks/ ansible/roles/
        
    - name: Ansible Syntax Check
      run: |
        ansible-playbook --syntax-check ansible/playbooks/scenarios/scenario-1-unpatched.yml
        ansible-playbook --syntax-check ansible/playbooks/scenarios/scenario-2-misconfig.yml
        ansible-playbook --syntax-check ansible/playbooks/scenarios/scenario-3-insider.yml
        
    - name: Molecule Test
      run: |
        cd ansible/roles/
        for role in */; do
          if [ -f "$role/molecule/default/molecule.yml" ]; then
            cd "$role"
            molecule test
            cd ..
          fi
        done
```

### security-scan.yml
```yaml
name: Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * 1'  # Еженедельно по понедельникам в 2:00

jobs:
  security-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
        
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
        
    - name: Run Bandit security linter
      uses: gaurav-nelson/github-action-bandit@v1
      with:
        path: "scripts/"
        
    - name: Run Semgrep
      uses: returntocorp/semgrep-action@v1
      with:
        config: >-
          p/security-audit
          p/secrets
          p/owasp-top-ten
          
    - name: Check for secrets
      uses: trufflesecurity/trufflehog@main
      with:
        path: ./
        base: main
        head: HEAD
        extra_args: --debug --only-verified
```

### deployment-test.yml
```yaml
name: Deployment Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deployment-test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        scenario: [scenario-1, scenario-2, scenario-3]
        
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
        
    - name: Setup Ansible
      run: |
        pip install ansible ansible-lint
        ansible-galaxy collection install community.general
        
    - name: Create test environment
      run: |
        # Создание тестовой среды с помощью Docker
        docker-compose -f tests/docker-compose.yml up -d
        
    - name: Deploy scenario
      run: |
        cd scenarios/${{ matrix.scenario }}/infrastructure/terraform
        terraform init
        terraform plan -var-file="test.tfvars"
        terraform apply -auto-approve -var-file="test.tfvars"
        
    - name: Run Ansible configuration
      run: |
        cd scenarios/${{ matrix.scenario }}/infrastructure/ansible
        ansible-playbook -i inventory.yml playbook.yml
        
    - name: Test scenario functionality
      run: |
        # Запуск тестов функциональности
        python tests/scenarios/test_${{ matrix.scenario }}.py
        
    - name: Cleanup test environment
      if: always()
      run: |
        cd scenarios/${{ matrix.scenario }}/infrastructure/terraform
        terraform destroy -auto-approve -var-file="test.tfvars"
        docker-compose -f tests/docker-compose.yml down
```

### scenario-test.yml
```yaml
name: Scenario Test

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'scenarios/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'scenarios/**'

jobs:
  scenario-test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        scenario: [scenario-1, scenario-2, scenario-3]
        
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup test environment
      run: |
        # Установка зависимостей для тестирования
        pip install pytest pytest-cov requests
        
    - name: Deploy test scenario
      run: |
        # Развертывание сценария в тестовой среде
        ./scripts/deployment/deploy-scenario.sh ${{ matrix.scenario }} tests/inventories/test-hosts.yml
        
    - name: Run vulnerability tests
      run: |
        # Тестирование уязвимостей
        python tests/scenarios/test_vulnerabilities.py --scenario ${{ matrix.scenario }}
        
    - name: Run exploitation tests
      run: |
        # Тестирование эксплуатации
        python tests/scenarios/test_exploitation.py --scenario ${{ matrix.scenario }}
        
    - name: Run remediation tests
      run: |
        # Тестирование устранения
        python tests/scenarios/test_remediation.py --scenario ${{ matrix.scenario }}
        
    - name: Generate test report
      run: |
        # Генерация отчета о тестировании
        python tests/generate_report.py --scenario ${{ matrix.scenario }}
        
    - name: Upload test artifacts
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results-${{ matrix.scenario }}
        path: |
          tests/results/
          tests/reports/
```

### documentation-build.yml
```yaml
name: Documentation Build

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'docs/**'
      - '*.md'
  pull_request:
    branches: [ main ]
    paths:
      - 'docs/**'
      - '*.md'

jobs:
  documentation-build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        
    - name: Install dependencies
      run: |
        pip install mkdocs mkdocs-material mkdocs-mermaid2-plugin
        
    - name: Build documentation
      run: |
        mkdocs build
        
    - name: Deploy to GitHub Pages
      if: github.ref == 'refs/heads/main'
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./site
        
    - name: Check for broken links
      run: |
        pip install linkchecker
        linkchecker site/index.html
```

### release.yml
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
        
    - name: Setup Ansible
      run: |
        pip install ansible ansible-lint
        ansible-galaxy collection install community.general
        
    - name: Run tests
      run: |
        # Запуск всех тестов перед релизом
        pytest tests/ --cov=src/ --cov-report=xml
        
    - name: Build release artifacts
      run: |
        # Создание артефактов релиза
        mkdir -p release/
        
        # Terraform модули
        tar -czf release/terraform-modules.tar.gz terraform/modules/
        
        # Ansible роли
        tar -czf release/ansible-roles.tar.gz ansible/roles/
        
        # Сценарии
        tar -czf release/scenarios.tar.gz scenarios/
        
        # Документация
        mkdocs build
        tar -czf release/documentation.tar.gz site/
        
    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        body: |
          ## Что нового в этой версии
          
          ### Новые функции
          - Добавлены новые сценарии
          - Улучшена документация
          - Обновлены инструменты безопасности
          
          ### Исправления
          - Исправлены ошибки в Terraform модулях
          - Улучшена стабильность Ansible плейбуков
          
          ### Безопасность
          - Обновлены зависимости
          - Исправлены уязвимости безопасности
        draft: false
        prerelease: false
        
    - name: Upload Release Assets
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./release/
        asset_name: release-assets
        asset_content_type: application/gzip
```

## Шаблоны Issues

### ISSUE_TEMPLATE/bug_report.md
```markdown
---
name: Отчет об ошибке
about: Создать отчет об ошибке для помощи в улучшении проекта
title: '[BUG] '
labels: bug
assignees: ''

---

**Описание ошибки**
Краткое и ясное описание ошибки.

**Шаги для воспроизведения**
Шаги для воспроизведения поведения:
1. Перейдите к '...'
2. Нажмите на '....'
3. Прокрутите вниз до '....'
4. Увидите ошибку

**Ожидаемое поведение**
Четкое и краткое описание того, что вы ожидали.

**Скриншоты**
Если применимо, добавьте скриншоты для объяснения вашей проблемы.

**Окружение (заполните следующую информацию):**
 - ОС: [например, Ubuntu 20.04]
 - Версия Terraform: [например, 1.5.0]
 - Версия Ansible: [например, 4.0.0]
 - Версия браузера: [например, Chrome 91]

**Дополнительный контекст**
Добавьте любой другой контекст об ошибке здесь.

**Логи**
```
Вставьте соответствующие логи здесь
```
```

### ISSUE_TEMPLATE/scenario_request.md
```markdown
---
name: Запрос нового сценария
about: Предложить новый учебный сценарий
title: '[SCENARIO] '
labels: enhancement, scenario
assignees: ''

---

**Описание сценария**
Краткое описание предлагаемого сценария.

**Цели обучения**
Какие навыки должны развивать студенты:
- [ ] Обнаружение уязвимостей
- [ ] Эксплуатация уязвимостей
- [ ] Реагирование на инциденты
- [ ] Форензический анализ
- [ ] Другие: ___

**Уровень сложности**
- [ ] Начальный
- [ ] Средний
- [ ] Продвинутый

**Время выполнения**
Предполагаемое время выполнения сценария: ___ часов

**Технологии**
Какие технологии должны быть задействованы:
- [ ] Веб-приложения
- [ ] Базы данных
- [ ] Сетевые сервисы
- [ ] Операционные системы
- [ ] Другие: ___

**Реальные примеры**
Ссылки на реальные инциденты или уязвимости, которые моделирует сценарий.

**Дополнительные требования**
Любые дополнительные требования или ограничения.
```

## Конфигурация Dependabot

### dependabot.yml
```yaml
version: 2
updates:
  # Terraform обновления
  - package-ecosystem: "terraform"
    directory: "/terraform"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 10
    
  # Python обновления
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 10
    
  # GitHub Actions обновления
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 10
    
  # Docker обновления
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
```

## CODEOWNERS

### CODEOWNERS
```
# Глобальные владельцы
* @security-team @devops-team

# Terraform
/terraform/ @devops-team @infrastructure-team

# Ansible
/ansible/ @devops-team @automation-team

# Сценарии
/scenarios/ @security-team @education-team

# Документация
/docs/ @documentation-team @education-team

# Тесты
/tests/ @qa-team @security-team

# CI/CD
/.github/ @devops-team @ci-team
```

## Дополнительные инструменты автоматизации

### Скрипты автоматизации (scripts/automation/)

```
scripts/automation/
├── ci-cd/                            # Скрипты CI/CD
│   ├── pre-commit-hooks.sh           # Pre-commit хуки
│   ├── post-commit-hooks.sh          # Post-commit хуки
│   ├── deployment-validation.sh      # Валидация развертывания
│   └── rollback-procedure.sh          # Процедура отката
├── testing/                          # Скрипты тестирования
│   ├── run-all-tests.sh              # Запуск всех тестов
│   ├── security-tests.sh              # Тесты безопасности
│   ├── performance-tests.sh           # Тесты производительности
│   └── integration-tests.sh          # Интеграционные тесты
├── deployment/                       # Скрипты развертывания
│   ├── deploy-infrastructure.sh      # Развертывание инфраструктуры
│   ├── deploy-scenarios.sh           # Развертывание сценариев
│   ├── update-configurations.sh       # Обновление конфигураций
│   └── cleanup-resources.sh           # Очистка ресурсов
└── monitoring/                        # Скрипты мониторинга
    ├── health-check.sh                # Проверка здоровья
    ├── performance-monitoring.sh      # Мониторинг производительности
    ├── security-monitoring.sh         # Мониторинг безопасности
    └── alert-management.sh            # Управление алертами
```

### Пример скрипта автоматизации

#### scripts/automation/ci-cd/pre-commit-hooks.sh
```bash
#!/bin/bash
# Pre-commit хуки для проверки кода

set -e

echo "Запуск pre-commit проверок..."

# Проверка форматирования Terraform
echo "Проверка форматирования Terraform..."
terraform fmt -check -recursive terraform/

# Проверка синтаксиса Ansible
echo "Проверка синтаксиса Ansible..."
ansible-playbook --syntax-check ansible/playbooks/scenarios/scenario-1-unpatched.yml
ansible-playbook --syntax-check ansible/playbooks/scenarios/scenario-2-misconfig.yml
ansible-playbook --syntax-check ansible/playbooks/scenarios/scenario-3-insider.yml

# Проверка безопасности
echo "Проверка безопасности..."
tfsec terraform/
ansible-lint ansible/playbooks/ ansible/roles/

# Проверка документации
echo "Проверка документации..."
markdownlint docs/ *.md

echo "Все pre-commit проверки пройдены успешно!"
```

## Лучшие практики CI/CD

1. **Автоматизация**: Максимальная автоматизация процессов
2. **Тестирование**: Комплексное тестирование всех компонентов
3. **Безопасность**: Интеграция проверок безопасности в CI/CD
4. **Мониторинг**: Непрерывный мониторинг качества кода
5. **Документация**: Автоматическая генерация документации
6. **Версионирование**: Семантическое версионирование релизов
7. **Откат**: Возможность быстрого отката изменений
8. **Уведомления**: Автоматические уведомления о статусе сборок

Эта структура CI/CD обеспечивает надежную автоматизацию процессов разработки и развертывания платформы киберучений.
