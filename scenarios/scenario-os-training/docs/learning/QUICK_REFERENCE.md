# Шпаргалка по командам для студентов

## 🔍 Обнаружение уязвимостей

### Ubuntu Server

#### Аутентификация

```bash
# Проверка пользователей
cat /etc/passwd

# Проверка настроек PAM
cat /etc/pam.d/common-password
grep minlen /etc/pam.d/common-password

# Проверка настроек sudo
sudo cat /etc/sudoers
sudo visudo -c

# Проверка политики паролей
sudo chage -l username
```

#### SSH

```bash
# Проверка конфигурации SSH
sudo cat /etc/ssh/sshd_config | grep -E "PermitRootLogin|PasswordAuthentication|MaxAuthTries"

# Проверка разрешенных алгоритмов
sudo sshd -T | grep -E "ciphers|macs|kexalgorithms"

# Проверка статуса fail2ban
systemctl status fail2ban
sudo fail2ban-client status
```

#### Firewall и сеть

```bash
# Проверка статуса UFW
sudo ufw status
sudo ufw status verbose

# Проверка открытых портов
sudo netstat -tulpn
sudo ss -tulpn

# Проверка запущенных служб
systemctl list-units --type=service --state=running
```

#### Права доступа

```bash
# Проверка прав на директории
ls -ld /etc /var /home

# Проверка прав на файлы
ls -l /etc/shadow
ls -l /etc/passwd

# Поиск директорий с правами 777
find / -type d -perm 777 2>/dev/null

# Поиск файлов с правами 777
find / -type f -perm 777 2>/dev/null
```

#### Обновления

```bash
# Проверка статуса обновлений
cat /etc/apt/apt.conf.d/50unattended-upgrades
systemctl status unattended-upgrades

# Проверка доступных обновлений
sudo apt update
sudo apt list --upgradable
```

---

### Windows Server 2016 / Windows 10

#### Аутентификация

```powershell
# Проверка политики паролей
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" | Select-Object MinimumPasswordLength

# Открыть Local Security Policy
secpol.msc

# Проверка учетных записей
Get-LocalUser
net user
```

#### Сеть

```powershell
# Проверка SMBv1
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# Проверка NTLM
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel"

# Проверка брандмауэра
Get-NetFirewallProfile | Select-Object Name, Enabled
Get-NetFirewallRule | Where-Object {$_.Enabled -eq $true} | Select-Object DisplayName, Direction, Action
```

#### Защита

```powershell
# Проверка UAC
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"

# Проверка Windows Defender
Get-MpComputerStatus
Get-MpPreference

# Проверка обновлений
Get-WUList
```

---

## 🔧 Исправление уязвимостей

### Ubuntu Server

#### Аутентификация

```bash
# Настройка PAM
sudo nano /etc/pam.d/common-password
# Изменить: password requisite pam_pwquality.so minlen=12

# Отключение root login
sudo nano /etc/ssh/sshd_config
# Установить: PermitRootLogin no
sudo systemctl restart sshd

# Настройка sudo
sudo visudo
# Удалить правила с NOPASSWD
```

#### SSH

```bash
# Отключение парольной аутентификации
sudo nano /etc/ssh/sshd_config
# Установить: PasswordAuthentication no
# Установить: MaxAuthTries 3

# Отключение слабых алгоритмов
# Добавить в /etc/ssh/sshd_config:
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com

sudo systemctl restart sshd

# Установка fail2ban
sudo apt update
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### Firewall

```bash
# Включение UFW
sudo ufw enable

# Настройка правил
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS

# Отключение небезопасных служб
sudo systemctl stop telnet
sudo systemctl disable telnet
sudo systemctl stop ftp
sudo systemctl disable ftp
```

#### Права доступа

```bash
# Исправление прав на директории
sudo chmod 755 /etc
sudo chmod 755 /var
sudo chmod 755 /home

# Исправление прав на /etc/shadow
sudo chmod 640 /etc/shadow
sudo chown root:shadow /etc/shadow

# Исправление всех директорий с правами 777
find / -type d -perm 777 2>/dev/null | while read dir; do
  sudo chmod 755 "$dir"
done
```

#### Обновления

```bash
# Включение автоматических обновлений
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

### Windows Server 2016 / Windows 10

#### Аутентификация

```powershell
# Настройка политики паролей через GUI
# Win + R → secpol.msc
# Account Policies → Password Policy

# Или через PowerShell (требуются права администратора)
# Установка минимальной длины пароля
net accounts /minpwlen:12

# Включение сложности паролей
net accounts /domain /uniquepw:24
```

#### Сеть

```powershell
# Отключение SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -Remove

# Отключение NTLMv1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Value 5

# Настройка брандмауэра
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
New-NetFirewallRule -DisplayName "Allow SMB" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
```

#### Защита

```powershell
# Включение UAC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1

# Включение Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Start-MpScan

# Включение автоматических обновлений
# Settings → Update & Security → Windows Update
```

---

## ✅ Проверка исправлений

### Автоматизированная проверка

```bash
# Быстрая проверка
cd infrastructure/scripts
./verify-fixes.sh

# Детальная проверка через Ansible
cd infrastructure/ansible
ansible-playbook -i inventory.yml verify-fixes.yml
```

### Ручная проверка

#### Ubuntu Server

```bash
# Проверка PAM
grep minlen /etc/pam.d/common-password

# Проверка SSH
sudo sshd -T | grep -E "passwordauthentication|permitrootlogin|maxauthtries"

# Проверка UFW
sudo ufw status verbose

# Проверка прав
ls -ld /etc /var /home
ls -l /etc/shadow
```

#### Windows

```powershell
# Проверка политики паролей
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" | Select-Object MinimumPasswordLength

# Проверка SMBv1
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# Проверка UAC
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"

# Проверка Windows Defender
Get-MpComputerStatus
```

---

## 🔗 Полезные ссылки

- Методические указания: `docs/learning/STUDENT_GUIDE.md`
- Описание уязвимостей: `docs/overview/machine-scenarios.md`
- Чеклист проверки: `docs/assessment/CHECKLIST.md`

---

## 💡 Полезные советы

1. **Всегда проверяйте результат** после исправления уязвимости
2. **Делайте скриншоты** для отчета
3. **Документируйте все действия** - это поможет при написании отчета
4. **Используйте автоматизированные проверки** для экономии времени
5. **Читайте выводы команд** - они содержат важную информацию

---

**Версия:** 1.0  
**Дата:** 2024

