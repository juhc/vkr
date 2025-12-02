# Учетные записи администраторов платформы

## Обзор

На всех машинах инфраструктуры созданы учетные записи администраторов платформы для управления и обслуживания систем.

## Учетные записи

### Основной администратор платформы

- **Имя пользователя**: `platform-admin`
- **Пароль**: `PlatformAdmin123!`
- **Права**: Полный sudo доступ
- **Группы**: `sudo`, `adm`, `platform-admins`
- **Оболочка**: `/bin/bash`

### Резервный администратор

- **Имя пользователя**: `backup-admin`
- **Пароль**: `BackupAdmin123!`
- **Права**: Полный sudo доступ
- **Группы**: `sudo`, `platform-admins`
- **Оболочка**: `/bin/bash`

## Доступ к машинам

### RADIUS сервер (192.168.10.10)

```bash
ssh platform-admin@192.168.10.10
```

### Биллинговый сервер (192.168.20.10)

```bash
ssh platform-admin@192.168.20.10
```

### Веб-сервер (192.168.20.20)

```bash
ssh platform-admin@192.168.20.20
```

### Сервер мониторинга (192.168.30.10)

```bash
ssh platform-admin@192.168.30.10
# или
ssh backup-admin@192.168.30.10
```

### Jump-сервер (192.168.30.20)

```bash
ssh platform-admin@192.168.30.20
# или
ssh backup-admin@192.168.30.20
```

## Настройка SSH ключей (рекомендуется)

Для безопасного доступа рекомендуется использовать SSH ключи вместо паролей:

### 1. Генерация SSH ключа

```bash
ssh-keygen -t ed25519 -C "platform-admin@internetplus.local" -f ~/.ssh/platform_admin_key
```

### 2. Копирование ключа на все машины

```bash
# На RADIUS сервер
ssh-copy-id -i ~/.ssh/platform_admin_key.pub platform-admin@192.168.10.10

# На биллинговый сервер
ssh-copy-id -i ~/.ssh/platform_admin_key.pub platform-admin@192.168.20.10

# На веб-сервер
ssh-copy-id -i ~/.ssh/platform_admin_key.pub platform-admin@192.168.20.20

# На сервер мониторинга
ssh-copy-id -i ~/.ssh/platform_admin_key.pub platform-admin@192.168.30.10

# На jump-сервер
ssh-copy-id -i ~/.ssh/platform_admin_key.pub platform-admin@192.168.30.20
```

### 3. Настройка SSH config

Добавьте в `~/.ssh/config`:

```
Host radius-server
    HostName 192.168.10.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key

Host billing-server
    HostName 192.168.20.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key

Host web-server
    HostName 192.168.20.20
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key

Host monitoring-server
    HostName 192.168.30.10
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key

Host jump-server
    HostName 192.168.30.20
    User platform-admin
    IdentityFile ~/.ssh/platform_admin_key
```

Теперь можно подключаться просто:

```bash
ssh radius-server
ssh billing-server
ssh web-server
ssh monitoring-server
ssh jump-server
```

## Изменение паролей

### Через Ansible

Измените пароли в файле `vulnerabilities.yml`:

```yaml
platform_admins:
  primary_admin:
    password: "YourNewPassword123!"
  backup_admin:
    password: "YourNewBackupPassword123!"
```

Затем примените изменения:

```bash
ansible-playbook -i inventory playbook.yml -e @vulnerabilities.yml
```

### Вручную на каждой машине

```bash
# Подключитесь к машине
ssh platform-admin@192.168.10.10

# Измените пароль
passwd
```

## Права доступа

Все учетные записи администраторов платформы имеют:
- Полный sudo доступ (NOPASSWD)
- Доступ к системным логам
- Доступ к конфигурационным файлам
- Права на перезапуск сервисов

## Безопасность

⚠️ **ВАЖНО**:

1. **Учетные записи администраторов платформы НЕ предназначены для эксплуатации уязвимостей**
   - Они созданы для управления и обслуживания инфраструктуры
   - Не используйте их для тестирования на проникновение

2. **Измените пароли после первого развертывания**
   - Пароли по умолчанию известны и небезопасны
   - Используйте сложные пароли

3. **Используйте SSH ключи**
   - Отключите доступ по паролю после настройки ключей
   - Храните приватные ключи в безопасном месте

4. **Ограничьте доступ**
   - Используйте firewall для ограничения доступа к SSH портам
   - Рассмотрите возможность использования VPN

## Информация о доступе

На каждой машине в домашней директории администратора создан файл `ACCESS_INFO.txt` с информацией о доступе:

```bash
cat ~/ACCESS_INFO.txt
```

## Устранение проблем

### Не могу подключиться по SSH

1. Проверьте, что SSH сервис запущен:
   ```bash
   sudo systemctl status ssh
   ```

2. Проверьте, что порт 22 открыт:
   ```bash
   sudo netstat -tlnp | grep :22
   ```

3. Проверьте логи SSH:
   ```bash
   sudo tail -f /var/log/auth.log
   ```

### Забыл пароль

Если вы забыли пароль администратора платформы:

1. Подключитесь к машине через консоль виртуальной машины
2. Загрузитесь в recovery mode
3. Сбросьте пароль через root доступ
4. Или пересоздайте учетную запись через Ansible

### Нужно добавить нового администратора

1. Добавьте учетную запись в `vulnerabilities.yml`:

```yaml
platform_admins:
  primary_admin:
    username: "platform-admin"
    password: "PlatformAdmin123!"
  backup_admin:
    username: "backup-admin"
    password: "BackupAdmin123!"
  new_admin:  # Новый администратор
    username: "new-admin"
    password: "NewAdmin123!"
```

2. Примените изменения через Ansible

## Дополнительная информация

- **Конфигурация**: `infrastructure/ansible/vulnerabilities.yml`
- **Ansible роль**: `ansible/roles/platform-admin/`
- **Документация роли**: `ansible/roles/platform-admin/README.md`

