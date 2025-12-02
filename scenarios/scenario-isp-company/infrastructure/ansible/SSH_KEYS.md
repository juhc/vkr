# Настройка SSH ключей для управления инфраструктурой

## Обзор

SSH ключи обеспечивают безопасный доступ к машинам инфраструктуры без использования паролей. Это более безопасный и удобный способ управления инфраструктурой.

## Быстрый старт

### Автоматическая настройка (рекомендуется)

Используйте скрипт для автоматической генерации и настройки ключей:

```bash
cd scenarios/scenario-isp-company/infrastructure/ansible/scripts
./setup-ssh-keys.sh
```

Скрипт выполнит:
1. Генерацию SSH ключей для администраторов
2. Обновление `vulnerabilities.yml` с путями к ключам
3. Применение ключей через Ansible (опционально)

### Ручная настройка

#### 1. Генерация SSH ключей

```bash
# Создайте директорию для ключей
mkdir -p scenarios/scenario-isp-company/infrastructure/ansible/keys

# Генерация ключа для platform-admin
ssh-keygen -t ed25519 -C "platform-admin@internetplus.local" \
    -f scenarios/scenario-isp-company/infrastructure/ansible/keys/platform_admin_key

# Генерация ключа для backup-admin
ssh-keygen -t ed25519 -C "backup-admin@internetplus.local" \
    -f scenarios/scenario-isp-company/infrastructure/ansible/keys/backup_admin_key
```

#### 2. Настройка vulnerabilities.yml

Добавьте пути к ключам в файл `vulnerabilities.yml`:

```yaml
platform_admins:
  primary_admin:
    username: "platform-admin"
    password: "PlatformAdmin123!"
    ssh_key_file: "keys/platform_admin_key.pub"  # Путь к публичному ключу
    # или прямо указать ключ:
    # ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."
  
  backup_admin:
    username: "backup-admin"
    password: "BackupAdmin123!"
    ssh_key_file: "keys/backup_admin_key.pub"
```

#### 3. Применение через Ansible

```bash
cd scenarios/scenario-isp-company/infrastructure/ansible
ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
```

## Способы указания SSH ключей

### Способ 1: Путь к файлу (рекомендуется)

```yaml
primary_admin:
  ssh_key_file: "keys/platform_admin_key.pub"
```

**Преимущества:**
- Ключи хранятся отдельно от конфигурации
- Легко обновлять ключи
- Не загромождает конфигурационный файл

### Способ 2: Прямой ключ в конфигурации

```yaml
primary_admin:
  ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
```

**Преимущества:**
- Все в одном файле
- Удобно для небольших проектов

### Способ 3: Список ключей

```yaml
primary_admin:
  ssh_keys:
    - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...key1"
    - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...key2"
```

**Преимущества:**
- Можно добавить несколько ключей для одного пользователя
- Удобно для команд с несколькими администраторами

## Использование скрипта setup-ssh-keys.sh

### Полная настройка

```bash
./setup-ssh-keys.sh
```

### Отдельные операции

```bash
# Только генерация ключей
./setup-ssh-keys.sh generate

# Только обновление конфигурации
./setup-ssh-keys.sh update-config

# Только применение через Ansible
./setup-ssh-keys.sh apply

# Показать информацию о ключах
./setup-ssh-keys.sh info
```

## Настройка SSH config

После генерации ключей скопируйте их в `~/.ssh/` и настройте SSH config:

```bash
# Копирование ключей
cp keys/platform_admin_key ~/.ssh/
cp keys/backup_admin_key ~/.ssh/

# Установка прав
chmod 600 ~/.ssh/platform_admin_key
chmod 600 ~/.ssh/backup_admin_key
```

Добавьте в `~/.ssh/config`:

```
Host radius-server
    HostName 192.168.10.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host billing-server
    HostName 192.168.20.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host web-server
    HostName 192.168.20.20
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host monitoring-server
    HostName 192.168.30.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes

Host jump-server
    HostName 192.168.30.20
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
    IdentitiesOnly yes
```

Теперь можно подключаться просто:

```bash
ssh radius-server
ssh billing-server
ssh web-server
ssh monitoring-server
ssh jump-server
```

## Отключение доступа по паролю

После настройки SSH ключей рекомендуется отключить доступ по паролю:

```yaml
platform_admins:
  access_settings:
    ssh_password_auth: false  # Отключить доступ по паролю
    ssh_key_auth: true        # Оставить доступ по ключам
```

Или автоматически:

```yaml
platform_admins:
  access_settings:
    disable_password_auth_after_keys: true  # Автоматически отключить после настройки ключей
```

## Ротация ключей

### Генерация новых ключей

```bash
# Создайте резервную копию старых ключей
mv keys/platform_admin_key keys/platform_admin_key.old
mv keys/platform_admin_key.pub keys/platform_admin_key.pub.old

# Сгенерируйте новые ключи
ssh-keygen -t ed25519 -C "platform-admin@internetplus.local" \
    -f keys/platform_admin_key
```

### Обновление на всех машинах

```bash
# Обновите vulnerabilities.yml с новым ключом
# Затем примените через Ansible
ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
```

### Удаление старых ключей

```bash
# На каждой машине удалите старый ключ из authorized_keys
ssh platform-admin@192.168.10.10
nano ~/.ssh/authorized_keys  # Удалите старый ключ
```

## Безопасность

### Рекомендации

1. **Храните приватные ключи в безопасности**
   - Права доступа: `chmod 600 ~/.ssh/*_key`
   - Не коммитьте приватные ключи в Git
   - Используйте менеджер паролей или безопасное хранилище

2. **Используйте сильные ключи**
   - Рекомендуется: `ed25519` или `RSA 4096`
   - Избегайте: `RSA 1024` или `DSA`

3. **Защищайте приватные ключи паролем**
   ```bash
   ssh-keygen -p -f ~/.ssh/platform_admin_key
   ```

4. **Ограничьте доступ по IP**
   - Используйте firewall для ограничения SSH доступа
   - Рассмотрите использование VPN

5. **Регулярно ротируйте ключи**
   - Меняйте ключи каждые 90-180 дней
   - Немедленно отзывайте скомпрометированные ключи

6. **Используйте SSH Agent**
   ```bash
   eval $(ssh-agent)
   ssh-add ~/.ssh/platform_admin_key
   ```

## Устранение проблем

### Ключ не работает

1. Проверьте права доступа:
   ```bash
   chmod 600 ~/.ssh/platform_admin_key
   chmod 644 ~/.ssh/platform_admin_key.pub
   chmod 700 ~/.ssh
   ```

2. Проверьте содержимое authorized_keys на сервере:
   ```bash
   ssh platform-admin@192.168.10.10
   cat ~/.ssh/authorized_keys
   ```

3. Проверьте логи SSH:
   ```bash
   sudo tail -f /var/log/auth.log
   ```

### Ansible не может загрузить ключ из файла

1. Проверьте путь к файлу (относительно директории ansible)
2. Убедитесь, что файл существует и читаем
3. Проверьте формат ключа (должен быть одна строка)

### Доступ по ключу не работает, но по паролю работает

1. Проверьте настройки SSH на сервере:
   ```bash
   sudo grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
   ```

2. Перезапустите SSH сервис:
   ```bash
   sudo systemctl restart ssh
   ```

## Дополнительные ресурсы

- **Скрипт настройки**: `scripts/setup-ssh-keys.sh`
- **Документация администраторов**: `PLATFORM_ADMINS.md`
- **Конфигурация**: `vulnerabilities.yml`
- **Ansible роль**: `ansible/roles/platform-admin/`

## Примеры использования

### Добавление ключа для нового администратора

```yaml
platform_admins:
  new_admin:
    username: "new-admin"
    password: "NewAdmin123!"
    ssh_key_file: "keys/new_admin_key.pub"
    sudo_access: true
```

### Использование существующего ключа

Если у вас уже есть SSH ключ:

```bash
# Скопируйте публичный ключ
cat ~/.ssh/id_ed25519.pub

# Добавьте в vulnerabilities.yml
primary_admin:
  ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...ваш_ключ"
```

### Настройка для команды

Для команды из нескольких администраторов:

```yaml
primary_admin:
  ssh_keys:
    - "{{ lookup('file', 'keys/admin1_key.pub') }}"
    - "{{ lookup('file', 'keys/admin2_key.pub') }}"
    - "{{ lookup('file', 'keys/admin3_key.pub') }}"
```

