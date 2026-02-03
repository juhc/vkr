# Packer для автоматической установки Windows на Proxmox

## Описание

Packer используется для автоматического создания шаблонов Windows VM в Proxmox. Это позволяет автоматизировать установку Windows ОС без ручного участия, используя файлы `autounattend.xml` для настройки процесса установки.

## Структура

```
packer/
├── README.md                    # Этот файл
├── variables.common.pkrvars.hcl.example   # Общие НЕсекретные переменные (пример)
├── variables.secrets.pkrvars.hcl.example  # Общие СЕКРЕТЫ (пример; НЕ коммитить)
├── windows-10/                 # Windows 10 (рабочая станция)
│   ├── windows-ws.pkr.hcl      # Packer конфигурация
│   └── variables.pkrvars.hcl   # Переменные этой ОС (НЕсекретные)
├── windows-11/                  # Windows 11
│   ├── windows-11.pkr.hcl
│   └── variables.pkrvars.hcl
├── windows-server/              # Windows Server
│   ├── windows-server.pkr.hcl  # Packer конфигурация
│   ├── variables.pkrvars.hcl
│   └── vars-20xx.pkrvars.hcl.example
└── domain-controller/            # Domain Controller
    ├── domain-controller.pkr.hcl # Packer конфигурация
    └── variables.pkrvars.hcl
```

## Требования

- **Packer** >= 1.9.0
- **Proxmox VE** с доступом через API
- **ISO образы Windows** загруженные в Proxmox или доступные по сети
- **SSH доступ** к Proxmox (для некоторых операций)
- **Инструмент для создания ISO** (для подготовки кастомных Windows ISO):
  - **Linux**: `xorriso` или `mkisofs` (пакет `genisoimage`)
  - **macOS**: `hdiutil` (встроен в систему)
  - **Windows**: `oscdimg` (часть Windows ADK - Assessment and Deployment Kit)

## Установка Packer

### Windows

```powershell
# Через Chocolatey
choco install packer

# Или скачайте с https://www.packer.io/downloads
```

### Linux

```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```

## Настройка

### 1. Создание API токена в Proxmox

1. Войдите в Proxmox Web UI
2. Перейдите в **Datacenter** → **Permissions** → **API Tokens**
3. Нажмите **Add** → **API Token**
4. Заполните:
   - **Token ID:** `packer@pam!packer-token`
   - **User:** `packer@pam` (или существующий пользователь)
   - **Privilege Separation:** включите
5. Сохраните **Token ID** и **Secret**

### 2. Подготовка ISO образов

ISO образы Windows должны быть доступны Packer. Варианты:

**Вариант 1: ISO в Proxmox storage (рекомендуется)**
- Загрузите ISO в Proxmox storage через веб-интерфейс:
  1. Proxmox Web UI → выберите узел → **Storage** → выберите storage (например, `local`)
  2. Вкладка **ISO Images** → **Upload**
  3. Выберите ISO файл и загрузите
- Укажите путь в конфигурации Packer: `iso_file = "local:iso/windows-10.iso"`

**Вариант 2: ISO по сети**
- Разместите ISO на HTTP/FTP сервере
- Укажите URL в конфигурации Packer: `iso_url = "http://server/path/to/windows.iso"`

**Важно:** ISO не хранятся в репозитории. Держите их в Proxmox storage (`local:iso/...`) или на HTTP/HTTPS.

**Подробнее:** См. [iso/README.md](iso/README.md) для детальных инструкций по работе с ISO образами.

### 3. Настройка переменных

#### Шаг 1: Общие НЕсекретные переменные

Создайте общий файл переменных в корне `packer/`:

```bash
cd infrastructure/packer
cp variables.common.pkrvars.hcl.example variables.common.pkrvars.hcl
# Отредактируйте variables.common.pkrvars.hcl (URL Proxmox, storage pools, bridge)
```

#### Шаг 2: Общие СЕКРЕТЫ (токены/пароли)

```bash
cd infrastructure/packer
cp variables.secrets.pkrvars.hcl.example variables.secrets.pkrvars.hcl
# Отредактируйте variables.secrets.pkrvars.hcl (token id/secret, пароли)
```

**Важно:** `variables.secrets.pkrvars.hcl` не коммитим (см. `packer/.gitignore`).

#### Шаг 3: Переменные для каждой ОС (НЕсекретные)

Файлы переменных в директориях ОС указывают только `iso_file`, `virtio_iso_file`, `vm_name`, `vm_id`, ресурсы VM и т.п.:
- `windows-10/variables.pkrvars.hcl`
- `windows-11/variables.pkrvars.hcl`
- `windows-server/variables.pkrvars.hcl`
- `domain-controller/variables.pkrvars.hcl`

## Использование

### Создание шаблонов

#### Вариант 1: Автоматическая сборка всех шаблонов

```bash
cd infrastructure/packer
chmod +x build-example.sh
./build-example.sh
```

#### Вариант 2: Ручная сборка каждой машины

**Рабочая станция Windows:**

```bash
cd windows-10
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

**Windows 11:**

```bash
cd ../windows-11
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

**Windows Server:**

```bash
cd windows-server
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

**Domain Controller:**

```bash
cd domain-controller
packer init .
packer validate -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
packer build -var-file="../variables.common.pkrvars.hcl" -var-file="../variables.secrets.pkrvars.hcl" -var-file="variables.pkrvars.hcl" .
```

**Важно:** используйте три `-var-file`:
1. `../variables.common.pkrvars.hcl`
2. `../variables.secrets.pkrvars.hcl`
3. `variables.pkrvars.hcl` (в директории ОС)

### Авто-подбор свободного VMID (без правки `vm_id` руками)

На Windows можно запускать сборку через PowerShell-скрипт, который получает свободный VMID через Proxmox API (`/cluster/nextid`)
и передаёт его в `packer build` как `-var vm_id=...`:

```powershell
cd stands\windows-stand\infrastructure\packer
.\scripts\Invoke-PackerBuildWithNextId.ps1 -Target windows-10
```

Доступные цели: `windows-10`, `windows-11`, `windows-server`, `domain-controller`.

## Процесс работы Packer

1. **Создание VM** - Packer создает временную VM в Proxmox
2. **Установка ОС** - Загружается **подготовленный ISO** и начинается установка Windows
3. **Автоматическая настройка** - Windows использует `autounattend.xml` из корня ISO
4. **Настройка через SSH** - Packer подключается по SSH (OpenSSH) для финальных шагов (и выключения)
6. **Создание шаблона** - После завершения VM конвертируется в шаблон
7. **Удаление временной VM** - Временная VM удаляется

## Ansible по SSH

Шаблоны включают **OpenSSH Server** (порт 22) для управления клонов через Ansible.
См. `ANSIBLE_WINDOWS_SSH.md`.

## Файл autounattend.xml

Файл `autounattend.xml` содержит настройки для автоматической установки Windows:

- Разметка диска
- Выбор раздела для установки
- Настройка региональных параметров
- Создание пользователя
- Настройка сети
- Установка драйверов

Файл `autounattend.xml` должен лежать **в корне вашего подготовленного ISO** (см. `scripts/CREATE_ISO_MANUAL.md`).

**Примечание:** Windows файловая система не чувствительна к регистру букв, поэтому `autounattend.xml` и `Autounattend.xml` работают одинаково. В официальной документации Microsoft используется `autounattend.xml` (с маленькой буквы), поэтому мы следуем этому соглашению.

### Где редактировать

- Исходники ISO (пример Win10): `iso/win10/`
- После правок пересоберите ISO: `scripts/rebuild-custom-iso.ps1`

## Интеграция с Terraform

После создания шаблона через Packer, используйте его в Terraform:

```hcl
# В terraform/windows-10/main.tf
clone = "windows-10-template"  # Имя шаблона, созданного Packer
```

## Устранение проблем

### Ошибка подключения к Proxmox

- Проверьте правильность API URL и токена
- Убедитесь, что токен имеет необходимые права
- Проверьте сетевую связность

### Ошибка при установке Windows

- Проверьте правильность пути к ISO
- Убедитесь, что установлен один из инструментов для создания ISO (xorriso, mkisofs, hdiutil, oscdimg)
- Проверьте логи установки в Proxmox

### Ошибка WinRM подключения

- Убедитесь, что WinRM настроен в `Autounattend.xml`
- Проверьте правила firewall
- Проверьте, что пользователь создан правильно

## Дополнительные ресурсы

- [Документация Packer Proxmox Builder](https://developer.hashicorp.com/packer/plugins/builders/proxmox)
- [Документация autounattend.xml](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [Windows System Image Manager](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/windows-system-image-manager-technical-reference)

---

**Версия:** 1.0  
**Дата:** 2024
