# Настройка таймаутов для Packer и Proxmox

## Параметры таймаутов в Packer

В конфигурации Packer (`windows-10/windows-ws.pkr.hcl`) добавлены следующие параметры:

```hcl
task_timeout              = "30m"  # Таймаут для задач Proxmox (30 минут)
task_status_check_interval = "10s"  # Интервал проверки статуса задач (10 секунд)
```

### Описание параметров:

- **`task_timeout`** - Максимальное время ожидания завершения задачи в Proxmox (создание VM, запуск, остановка и т.д.)
  - По умолчанию: может быть коротким (1-5 минут)
  - Рекомендуется: `30m` для установки Windows
  
- **`task_status_check_interval`** - Как часто Packer проверяет статус задачи в Proxmox
  - По умолчанию: может быть коротким (1-2 секунды)
  - Рекомендуется: `10s` для снижения нагрузки на API

## Проверка таймаутов в Proxmox

### 1. Проверка таймаутов веб-сервера (pveproxy)

Подключитесь к Proxmox по SSH и выполните:

```bash
# Проверка конфигурации pveproxy
cat /etc/default/pveproxy

# Проверка таймаутов в конфигурации
grep -i timeout /etc/default/pveproxy

# Проверка логов pveproxy
tail -f /var/log/pveproxy/access.log
```

### 2. Проверка таймаутов API

```bash
# Проверка конфигурации API
cat /etc/pve/local/pve-www.conf

# Проверка таймаутов в конфигурации
grep -i timeout /etc/pve/local/pve-www.conf
```

### 3. Проверка таймаутов задач

```bash
# Проверка статуса задач
pvesh get /cluster/tasks

# Проверка конкретной задачи
pvesh get /nodes/pve/tasks/{task-id}/status
```

## Настройка таймаутов в Proxmox

### Увеличение таймаутов веб-сервера

Отредактируйте файл `/etc/default/pveproxy`:

```bash
sudo nano /etc/default/pveproxy
```

Добавьте или измените параметры:

```bash
# Таймаут для HTTP соединений (в секундах)
PROXY_TIMEOUT=300

# Таймаут для keep-alive соединений
KEEPALIVE_TIMEOUT=60
```

Перезапустите сервис:

```bash
sudo systemctl restart pveproxy
```

### Увеличение таймаутов API

Отредактируйте файл `/etc/pve/local/pve-www.conf`:

```bash
sudo nano /etc/pve/local/pve-www.conf
```

Добавьте параметры:

```nginx
# Таймаут для API запросов (в секундах)
client_body_timeout 300;
client_header_timeout 300;
send_timeout 300;
```

Перезапустите сервис:

```bash
sudo systemctl restart pveproxy
```

## Отключение таймаутов (не рекомендуется)

**ВНИМАНИЕ:** Полное отключение таймаутов не рекомендуется, так как это может привести к зависанию соединений.

Если необходимо увеличить таймауты до очень больших значений:

### В Packer:

```hcl
task_timeout = "2h"  # 2 часа (максимальное значение)
```

### В Proxmox:

```bash
# В /etc/default/pveproxy
PROXY_TIMEOUT=3600  # 1 час
```

## Диагностика проблем с таймаутами

### 1. Проверка логов Proxmox

```bash
# Логи pveproxy
tail -f /var/log/pveproxy/access.log

# Логи syslog
tail -f /var/log/syslog | grep -i timeout

# Логи задач
pvesh get /cluster/tasks --output-format json | jq
```

### 2. Проверка сетевых соединений

```bash
# Проверка активных соединений
netstat -an | grep 8006

# Проверка таймаутов TCP
ss -o state established '( dport = :8006 )'
```

### 3. Включение отладки

```bash
# Включение отладки Proxmox
echo "1" > /etc/pve/.debug

# Перезапуск сервисов
systemctl restart pveproxy
```

## Рекомендуемые значения

Для установки Windows через Packer:

- **Packer `task_timeout`**: `30m` (30 минут)
- **Packer `task_status_check_interval`**: `10s` (10 секунд)
- **Proxmox `PROXY_TIMEOUT`**: `300` (5 минут)
- **Proxmox API таймауты**: `300` (5 минут)

## Устранение ошибки "connection forcibly closed"

Если вы видите ошибку `wsarecv: An existing connection was forcibly closed by the remote host`:

1. **Проверьте стабильность Proxmox**:
   ```bash
   systemctl status pveproxy
   systemctl status pvedaemon
   ```

2. **Увеличьте таймауты** (как описано выше)

3. **Проверьте сетевую связность**:
   ```bash
   ping <proxmox-ip>
   telnet <proxmox-ip> 8006
   ```

4. **Проверьте логи на ошибки**:
   ```bash
   tail -100 /var/log/syslog | grep -i error
   ```

5. **Перезапустите сервисы Proxmox**:
   ```bash
   systemctl restart pveproxy
   systemctl restart pvedaemon
   ```
