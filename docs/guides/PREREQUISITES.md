## Требования и подготовка окружения (чтобы всё работало)

Документ описывает минимальные требования к:
- машине администратора (откуда запускаются Packer/Terraform/Ansible),
- Proxmox VE,
- шаблонам ВМ (Linux cloud-init и Windows/DC),
- сети/VPN,
- переменным/секретам в репозитории.

---

### 1) Требования к машине администратора

Нужно ПО:
- **Terraform** (1.x): применяется для создания ВМ в Proxmox.
- **Ansible** (2.15+ рекомендуется): применяется для пост‑настройки (пользователи/уязвимости/AD org).
- **Packer** (если собираете Windows template через Packer): для `stands/windows-stand/infrastructure/packer/`.
- **SSH-клиент**: для подключения Ansible к Linux и Windows (Windows управляется по SSH + PowerShell).
- **Python 3** (для Ansible на Windows/Linux: локально на машине администратора).

Рекомендуется:
- **Git**
- **Менеджер секретов (опционально)**: Ansible Vault / 1Password / KeePass / переменные CI

ОС администратора:
- Можно Windows или Linux/macOS.
- Скрипты для Linux cloud-init templates есть в PowerShell и bash (см. `stands/linux-stand/infrastructure/templates/`).

---

### 2) Требования к Proxmox VE

- Proxmox VE с доступом к API (`https://<pve>:8006/api2/json`).
- Наличие:
  - **node** (например `pve`),
  - **storage** для дисков ВМ и cloud-init (`local-lvm` и т.п.),
  - **bridge** (например `vmbr0`) для сетевых интерфейсов ВМ.
- Для Terraform: **API Token** с правами создавать/клонировать ВМ (в рамках выбранного node/storage).

Рекомендуется:
- **Включить QEMU Guest Agent (рекомендуется/желательно)**:
  - в конфигурации ВМ/шаблонов в Proxmox (`agent=1`),
  - и установить/запустить агент **внутри гостевой ОС** (Linux/Windows).
  
  Это даёт корректные статусы, shutdown/reboot, и упрощает диагностику. В Terraform и скриптах шаблонов уже выставляется `agent=1`, но без установленного агента внутри ВМ это работать не будет.

Как проверить (по желанию):
- Proxmox: в UI в VM → Options/Configuration убедиться, что **QEMU Guest Agent = Enabled**.
- Proxmox CLI: `qm agent <vmid> ping` (если доступно на вашей ноде).
- Linux внутри ВМ: `systemctl status qemu-guest-agent`.
- Windows внутри ВМ: проверить службу “QEMU Guest Agent” (в Services) или `Get-Service`.

---

### 3) Требования к сети/VPN

Так как обучающийся/админ подключаются по VPN:
- Машина администратора должна иметь L3‑доступ до IP ВМ (SSH на 22/другие порты по политике курса).
- Для домена:
  - Клиенты должны видеть **DC по сети**.
  - DNS для клиентов должен указывать на **DC** (для join). В роли `vkr_ad_join` это настраивается автоматически, если `vkr_ad_configure_dns: true`.

Если Linux‑стенд и Windows‑стенд в разных подсетях (например `192.168.102.0/24` и `192.168.101.0/24`), нужен маршрут между подсетями или размещение DC/клиентов в доступной топологии (в зависимости от вашей архитектуры).

---

### 4) Требования к шаблонам ВМ

#### 4.1 Linux (cloud-init template)

Требования:
- Cloud-image (qcow2) + cloud-init.
- В шаблоне должен существовать пользователь для Ansible (обычно `ansible`) или он создаётся cloud-init.
- Доступ по SSH (ключ/пароль) должен позволять Ansible подключиться.
- **QEMU Guest Agent**: установить пакет `qemu-guest-agent` и включить сервис (рекомендуется).

Где хранится:
- `stands/linux-stand/infrastructure/templates/` — создание cloud-init templates.

#### 4.2 Windows (Windows 10 / Windows Server)

Требования (критично):
- **OpenSSH Server включён** в шаблоне.
- Пользователь для Ansible **существует** (обычно `ansible`) и может подключаться по SSH.
- Shell для Ansible: **PowerShell** (в inventory уже настроено `ansible_shell_type: powershell`).
- **QEMU Guest Agent (рекомендуется)**: установить `QEMU Guest Agent`/VirtIO guest tools (обычно с VirtIO ISO) и убедиться, что служба агента запущена.

> Идея: Ansible работает по SSH, поэтому WinRM не обязателен.

#### 4.3 Domain Controller (AD DS)

В текущей логике проекта **DC должен быть “готовым” Domain Controller**, то есть:
- AD DS роль установлена,
- лес/домен уже создан (например `training.local`),
- DC функционирует как DNS для домена.

Далее Ansible:
- добавляет AD/GPO‑уязвимости (`vkr_vuln_ad`),
- выполняет организационную автоматизацию (OU/группы/линковка и фильтрация GPO) (`vkr_ad_org`).

---

### 5) Что нужно заполнить в репозитории (переменные/секреты)

#### 5.1 Terraform

Для каждой ВМ копируете `terraform.tfvars.example` → `terraform.tfvars` и заполняете:
- `proxmox_api_url`, `proxmox_api_token_id`, `proxmox_api_token_secret`
- `proxmox_node`, `storage`, `proxmox_bridge`
- IP/шлюз/DNS (если static) или DHCP параметры

> Файлы `*.tfvars` не коммитятся (см. `.gitignore`).

#### 5.2 Ansible: учётки/AD/уязвимости

В каждом стенде:
- `group_vars/all/accounts.yml` (из `accounts.yml.example`) — какие пользователи/группы должны быть на ВМ.
- `group_vars/all/vulnerabilities.yml` — какие уязвимости включены (`vuln_profiles.*`).
- `group_vars/all/ad.yml` (из `ad.yml.example`) — параметры домена и включение/выключение domain join:
  - `vkr_ad_domain_name`, `vkr_ad_dc_ip`
  - `vkr_ad_join_user`, `vkr_ad_join_password` (хранить локально; **не коммитить**)
  - `vkr_ad_join_profiles.*` (true/false)
  - “организационная” часть для GPO:
    - `vkr_ad_org_enabled`
    - `vkr_ad_training_ou`, `vkr_ad_stand_ou`, `vkr_ad_stand_id`
    - `vkr_ad_stand_computers` — **COMPUTERNAME** доменных хостов стенда

---

### 6) Порядок деплоя (в общих чертах)

- Windows стенд: `stands/windows-stand/infrastructure/scripts/deploy.sh`
  - Terraform создаёт ВМ (DC, Windows 10, Windows Server)
  - Ansible:
    - настраивает DC (OS+AD уязвимости),
    - клиенты делают domain join,
    - DC запускается повторно (post‑join) для OU/GPO scope и filtering

- Linux стенд: `stands/linux-stand/infrastructure/scripts/deploy.sh`
  - Terraform создаёт Linux ВМ из cloud-init templates
  - Ansible настраивает учётки/уязвимости, и (если включено) domain join

