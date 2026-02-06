## Proxmox доступ для обучающихся (по VPN) — только “свои” ВМ стенда

Цель: обучающийся заходит в Proxmox Web UI и **видит только ВМ своего стенда**, может **включать/выключать/перезагружать** и **открывать консоль**, но **не видит** другие ВМ/пулы/хранилища/ноды и **не может менять конфигурацию**.

### Базовая схема (рекомендуется)

- **1 стенд = 1 Pool** в Proxmox.
- Все ВМ стенда добавляются в этот Pool.
- Для студентов создаётся роль с минимальными правами на уровне **Pool**.

### Какие права дать студенту (минимально)

Создайте роль, например `StudentVM` со следующими правами:

- **VM.Audit** — видеть VM/статусы
- **VM.Console** — открывать noVNC/SPICE console
- **VM.PowerMgmt** — start/stop/reboot/reset
- (опционально) **VM.Monitor** — просмотр состояния/метрик

**Не выдавайте** студенту права типа `VM.Config.*`, `Datastore.*`, `Sys.*`, `Permissions.Modify`.

### Настройка через Proxmox UI (коротко)

1) **Datacenter → Pools → Create**: создайте пул, например `stand-linux-01` или `stand-windows-01`.
2) Добавьте ВМ (VMID) стенда в пул.
3) **Datacenter → Permissions → Roles → Create**: создайте роль `StudentVM` и отметьте нужные права (см. выше).
4) **Datacenter → Permissions → Users → Add**: создайте пользователя (например `student01@pve`) или подключите LDAP/AD realm.
5) **Datacenter → Permissions → Add → Pool permission**:
   - Path: `/pool/stand-linux-01`
   - User: `student01@pve`
   - Role: `StudentVM`
   - Propagate: ✅

Результат: студент видит только ресурсы, попавшие в его pool.

### Настройка через CLI (pveum) — пример

> Выполняется на ноде Proxmox.

```bash
# 1) роль (минимальные права)
pveum role add StudentVM -privs "VM.Audit VM.Console VM.PowerMgmt"

# 2) пользователь (локальный realm pve)
pveum user add student01@pve
pveum passwd student01@pve

# 3) пул и привязка прав
pvesh create /pools -poolid stand-linux-01
# далее добавьте VM в pool через UI (или pvesh, если у вас настроено)

# 4) права на pool
pveum aclmod /pool/stand-linux-01 -user student01@pve -role StudentVM
```

### Как это сочетается с Ansible/Terraform

- Студент **не нужен** для Ansible/Terraform. Эти инструменты остаются у администратора (API token/SSH keys).
- Студент включает ВМ, затем подключается к ним по VPN (например SSH/RDP) уже “как пользователь стенда”.

### Рекомендации по безопасности

- Делайте доступ в Proxmox **только через VPN**.
- Включите **2FA** для пользователей Proxmox (если это возможно в вашей политике).
- Логи: фиксируйте действия студентов (Audit).
