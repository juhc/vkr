# Быстрый старт с Packer для Windows стенда

## Шаг 1: Установка Packer

### Windows
```powershell
choco install packer
```

### Linux
```bash
# См. README.md для подробных инструкций
```

## Шаг 2: Настройка Proxmox API токена

1. Войдите в Proxmox Web UI
2. **Datacenter** → **Permissions** → **API Tokens** → **Add**
3. Создайте токен с правами на создание VM
4. Сохраните Token ID и Secret

## Шаг 3: Подготовка ISO образов

### Вариант 1: Загрузка ISO в Proxmox storage (рекомендуется)

**Через веб-интерфейс:**
1. Proxmox Web UI → выберите узел → **Storage** → выберите storage (например, `local`)
2. Вкладка **ISO Images** → **Upload**
3. Выберите ISO файл и загрузите

**Через командную строку:**
```bash
# Скопируйте ISO в Proxmox
scp windows-10.iso root@proxmox-server:/var/lib/vz/template/iso/
```

### Примечание про ISO

В этом репозитории ISO **не хранятся**. Загрузите ISO в Proxmox storage (рекомендуется) и используйте `local:iso/...`.

## Шаг 4: Настройка переменных

### Шаг 4.1: Общие НЕсекретные переменные

Сначала создайте общий файл переменных в корне `packer/`:

```bash
cd infrastructure/packer
cp variables.common.pkrvars.hcl.example variables.common.pkrvars.hcl
# Отредактируйте variables.common.pkrvars.hcl (URL Proxmox, storage pools, bridge)
```

### Шаг 4.2: Общие СЕКРЕТЫ (токены/пароли)

```bash
cd infrastructure/packer
cp variables.secrets.pkrvars.hcl.example variables.secrets.pkrvars.hcl
# Отредактируйте variables.secrets.pkrvars.hcl (token id/secret, пароли)
```

**Важно:** `variables.secrets.pkrvars.hcl` не коммитим.

### Шаг 4.3: Переменные для каждой ОС

Файлы ОС:
- `windows-10/variables.pkrvars.hcl`
- `windows-11/variables.pkrvars.hcl`
- `windows-server/variables.pkrvars.hcl`
- `domain-controller/variables.pkrvars.hcl`

**Важно:** не храните токены/пароли в файлах ОС.

## Шаг 5: Создание шаблонов

### Вариант 1: Автоматическая сборка всех шаблонов

```bash
cd infrastructure/packer
chmod +x build-example.sh
./build-example.sh
```

### Вариант 2: Ручная сборка каждой машины

#### Рабочая станция Windows

```bash
cd windows-10
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

### Вариант 3 (Windows): авто-подбор свободного VMID

```powershell
cd stands\scenario-windows-stand\infrastructure\packer
.\scripts\Invoke-PackerBuildWithNextId.ps1 -Target windows-10
```

Linux/macOS (bash):

```bash
cd stands/scenario-windows-stand/infrastructure/packer
./scripts/Invoke-PackerBuildWithNextId.sh windows-10
```


#### Windows Server

```bash
cd ../windows-server
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

#### Domain Controller

```bash
cd ../domain-controller
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

**Важно:** используйте три `-var-file`:

- `../variables.common.pkrvars.hcl`
- `../variables.secrets.pkrvars.hcl`
- `variables.pkrvars.hcl` (в директории ОС)

## Шаг 6: Использование шаблонов в Terraform

После создания шаблонов обновите Terraform конфигурации:

```hcl
# infrastructure/terraform/windows-10/main.tf
clone = "windows-10-ws-template"  # Имя шаблона из Packer
```

## Устранение проблем

### Ошибка: "Failed to connect to Proxmox"

- Проверьте правильность `proxmox_api_url`
- Убедитесь, что токен имеет права на создание VM
- Проверьте сетевую связность

### Ошибка: "ISO file not found"

- Проверьте правильность пути к ISO в `iso_file`
- Убедитесь, что ISO загружен в указанный storage pool
- Проверьте права доступа

### Ошибка: "WinRM connection timeout"

- Убедитесь, что WinRM настроен в `autounattend.xml`
- Проверьте, что пароль правильный
- Увеличьте `winrm_timeout` в конфигурации Packer

### Windows не устанавливается автоматически

- Убедитесь, что установлен инструмент для создания ISO (xorriso, mkisofs, hdiutil или oscdimg)
- Проверьте правильность `autounattend.xml`
- Убедитесь, что ISO содержит нужную редакцию Windows
- Проверьте логи установки в Proxmox
- **Примечание:** Windows не чувствительна к регистру, но в документации используется `autounattend.xml` (с маленькой буквы)

## Следующие шаги

После создания шаблонов вы можете клонировать VM и настраивать их через Ansible по SSH.
См. `ANSIBLE_WINDOWS_SSH.md`.

---

**Дополнительная информация:** См. [README.md](README.md) для подробной документации.
