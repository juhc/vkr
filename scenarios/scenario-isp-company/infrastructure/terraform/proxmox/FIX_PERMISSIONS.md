# Исправление ошибок токена Proxmox

## Проблема 1: Недостаточно прав (VM.Monitor)

Ошибка: `Error: permissions for user/token root@pam are not sufficient, please provide also the following permissions that are missing: [VM.Monitor]`

Даже если у токена есть роль "administrator", Proxmox требует **конкретные права** для работы через API.

## Проблема 2: Privilege Separation

Ошибка: `Error: user terraform@pam has valid credentials but cannot retrieve user list, check privilege separation of api token`

Эта ошибка возникает, когда у токена включена опция **"Privilege Separation"**, которая ограничивает права токена.

## Решение 1: Использование роли PVEVMAdmin (рекомендуется)

### Шаг 1: Проверка текущих прав токена

1. Откройте веб-интерфейс Proxmox
2. Перейдите: **Datacenter → Permissions → API Tokens**
3. Найдите ваш токен (`root@pam!test`)
4. Нажмите на токен
5. Проверьте вкладку **Permissions** - какие права там указаны

### Шаг 2: Добавление роли PVEVMAdmin

1. В веб-интерфейсе Proxmox перейдите: **Datacenter → Permissions → API Tokens**
2. Найдите ваш токен (`root@pam!test`)
3. Нажмите на токен
4. Перейдите на вкладку **Permissions**
5. **Удалите** все существующие права (если есть)
6. Нажмите **Add**
7. Добавьте:
   - **Path**: `/` (корень Datacenter - важно!)
   - **Role**: `PVEVMAdmin`
8. Нажмите **Add**

### Шаг 3: Проверка

После добавления прав выполните:

```bash
terraform plan
```

Если ошибка исчезла - права настроены правильно!

## Решение 2: Добавление конкретных прав (если PVEVMAdmin не работает)

Если роль PVEVMAdmin не доступна или не работает, добавьте права напрямую:

1. Перейдите: **Datacenter → Permissions → API Tokens → [ваш токен] → Permissions**
2. Нажмите **Add**
3. Добавьте права по одному:

   **Первое право:**
   - **Path**: `/`
   - **Role**: выберите **Custom** или создайте роль с правами:
     - `VM.Monitor` ✅ (обязательно!)
     - `VM.Allocate`
     - `VM.Clone`
     - `VM.Config.Disk`
     - `VM.Config.Network`
     - `VM.Config.Options`
     - `VM.PowerMgmt`
     - `Datastore.Allocate`
     - `Datastore.AllocateSpace`

## Решение 3: Отключение Privilege Separation

Если вы видите ошибку `check privilege separation of api token`:

1. Откройте веб-интерфейс Proxmox
2. Перейдите: **Datacenter → Permissions → API Tokens**
3. Найдите ваш токен (например, `terraform@pam!zxc`)
4. Нажмите на токен
5. Перейдите на вкладку **Token**
6. **ОТКЛЮЧИТЕ** опцию **"Privilege Separation"** (снимите галочку)
7. Сохраните изменения

**Важно**: Privilege Separation ограничивает права токена и может мешать работе Terraform.

## Решение 4: Создание кастомной роли (для продвинутых)

Если нужно создать свою роль:

1. Перейдите: **Datacenter → Permissions → Roles**
2. Нажмите **Create**
3. Название роли: `TerraformRole`
4. Добавьте права:
   - `VM.Monitor`
   - `VM.Allocate`
   - `VM.Clone`
   - `VM.Config.Disk`
   - `VM.Config.Network`
   - `VM.Config.Options`
   - `VM.PowerMgmt`
   - `Datastore.Allocate`
   - `Datastore.AllocateSpace`
   - `SDN.Use`
5. Сохраните роль
6. Назначьте роль токену (см. Решение 1, шаг 2)

## Решение 4: Проверка через веб-интерфейс Proxmox

**Важно**: Убедитесь, что права назначены правильно:

1. Откройте веб-интерфейс Proxmox
2. Перейдите: **Datacenter → Permissions → API Tokens**
3. Найдите токен `root@pam!test`
4. **Проверьте вкладку Permissions**:
   - Должна быть запись с **Path: `/`** (корень, не `/nodes/pve`!)
   - Должна быть роль **`PVEVMAdmin`** или права включают **`VM.Monitor`**

### Если права есть, но не работают:

1. **Удалите все права токена**
2. **Добавьте заново** с Path = `/` и Role = `PVEVMAdmin`
3. **Сохраните** и подождите 10-30 секунд (Proxmox может кэшировать права)
4. Попробуйте снова: `terraform plan`

### Проверка прав через командную строку Proxmox:

Если у вас есть SSH доступ к Proxmox серверу:

```bash
# Проверка прав токена
pveum token list
pveum token permissions root@pam!test
```

### Создание нового токена с нуля:

Если ничего не помогает, создайте новый токен:

1. **Datacenter → Permissions → API Tokens → Add**
2. **User ID**: `root@pam`
3. **Token ID**: `terraform-test`
4. Нажмите **Generate** и **сохраните Token Secret**
5. **Сразу после создания** добавьте права:
   - **Path**: `/`
   - **Role**: `PVEVMAdmin`
6. Обновите `terraform.tfvars` с новым токеном

## Важные замечания

### Путь (Path) критически важен!

- ✅ **Правильно**: Path = `/` (корень Datacenter)
- ❌ **Неправильно**: Path = `/nodes/pve` или другой путь

Права должны быть назначены на **корень Datacenter** (`/`), а не на конкретный узел!

### Проверка прав через API

Можно проверить права токена через API:

```bash
# Замените значения на свои
curl -k -H "Authorization: PVEAuthCookie=root@pam!test=3c88a9c7-dc7e-455f-ad07-1adaa076dc80" \
  https://127.0.0.1:8006/api2/json/access/permissions
```

### Типичные ошибки

1. **Права назначены на узел, а не на Datacenter**
   - ❌ Path: `/nodes/pve`
   - ✅ Path: `/`

2. **Использована неправильная роль**
   - ❌ Role: `Administrator` (может не включать VM.Monitor)
   - ✅ Role: `PVEVMAdmin`

3. **Права назначены пользователю, а не токену**
   - Убедитесь, что права назначены именно **токену**, а не пользователю

## Проверка после настройки

После настройки прав выполните:

```bash
terraform plan
```

Если ошибка `VM.Monitor` исчезла, но появилась другая (например, `VM.Allocate`), добавьте недостающие права.

## Дополнительная диагностика

Если ничего не помогает:

1. **Проверьте версию Proxmox**: `pveversion` (должна быть 7.0+)
2. **Проверьте логи Proxmox**: `/var/log/pveproxy/access.log`
3. **Попробуйте создать новый токен** с нуля
4. **Используйте пользователя root напрямую** (для тестирования)

---

**После настройки прав токен должен работать с Terraform!**

