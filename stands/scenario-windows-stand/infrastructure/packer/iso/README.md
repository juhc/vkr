# Директория для ISO образов Windows

## Описание

Эта директория предназначена для хранения ISO образов Windows, которые будут использоваться Packer для создания шаблонов виртуальных машин.

## Использование

### Важно

ISO **не хранятся в репозитории**. Этот каталог содержит только документацию.
Рекомендуемый вариант — загрузить ISO в Proxmox storage и ссылаться на него как `local:iso/...`.

### Вариант 2: ISO в Proxmox storage

Если ISO уже загружен в Proxmox storage, укажите его имя:

```hcl
# В variables.pkrvars.hcl
iso_file = "local:iso/windows-10.iso"  # ISO в Proxmox storage "local"
```

### Вариант 3: ISO по HTTP/HTTPS

Если ISO размещен на HTTP сервере, используйте URL:

```hcl
# В variables.pkrvars.hcl
iso_url = "http://server.example.com/iso/windows-10.iso"
iso_checksum = "sha256:checksum-here"
```

## Рекомендуемые имена файлов

Для удобства используйте понятные имена:

- `windows-10-pro.iso` - Windows 10 Pro
- `windows-11-pro.iso` - Windows 11 Pro
- `windows-server-2016.iso` - Windows Server 2016
- `windows-server-2019.iso` - Windows Server 2019
- `windows-server-2022.iso` - Windows Server 2022

## Загрузка ISO в Proxmox

### Через веб-интерфейс

1. Войдите в Proxmox Web UI
2. Выберите узел → **Storage** → выберите storage (например, `local`)
3. Перейдите на вкладку **ISO Images**
4. Нажмите **Upload**
5. Выберите ISO файл и загрузите

### Через командную строку

```bash
# Копирование ISO в Proxmox storage
scp windows-10.iso root@proxmox-server:/var/lib/vz/template/iso/
```

Или через Proxmox API:

```bash
# Используйте curl или другой инструмент для загрузки через API
```

## Проверка наличия ISO

После загрузки ISO в Proxmox, проверьте его наличие:

1. В веб-интерфейсе: **Storage** → выберите storage → **ISO Images**
2. Через командную строку:
   ```bash
   ssh root@proxmox-server "ls -lh /var/lib/vz/template/iso/"
   ```

## Настройка в Packer

После размещения ISO, укажите его в `*/variables.pkrvars.hcl` для конкретной ОС:

```hcl
# Для рабочей станции Windows
iso_file = "local:iso/windows-10.iso"

# Для Windows Server
iso_file = "local:iso/windows-server-2019.iso"

# Для Domain Controller
iso_file = "local:iso/windows-server-2019.iso"
```

## Примечания

- **Размер файлов:** ISO образы Windows обычно занимают 4-6 ГБ. Убедитесь, что есть достаточно места.
- **Формат:** Используйте оригинальные ISO образы от Microsoft или проверенные источники.
- **Версии:** Убедитесь, что версия ISO соответствует указанной в `windows_edition` в конфигурации Packer.
- **Безопасность:** ISO файлы не должны содержать вирусов или модификаций.

## Git

ISO файлы обычно не добавляются в Git из-за их размера. Директория `iso/` добавлена в `.gitignore`.

Если нужно поделиться ISO файлами, используйте:
- Общий сетевой диск
- Облачное хранилище
- Локальный файловый сервер

---

**Версия:** 1.0  
**Дата:** 2024
