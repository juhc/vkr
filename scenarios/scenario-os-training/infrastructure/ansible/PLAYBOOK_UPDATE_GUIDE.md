# Руководство по обновлению playbook для выборочного включения уязвимостей

## Обзор

Для включения выборочного управления уязвимостями нужно добавить условия `when:` к каждой категории задач в playbook.

## Паттерн обновления

### До обновления:

```yaml
- name: Создание пользователей со слабыми паролями
  user:
    name: "{{ item.name }}"
    password: "{{ item.password | password_hash('sha512') }}"
    # ...
```

### После обновления:

```yaml
- name: Создание пользователей со слабыми паролями
  user:
    name: "{{ item.name }}"
    password: "{{ item.password | password_hash('sha512') }}"
    # ...
  when: ubuntu_vulnerabilities.auth_weak_passwords | default(true)
  tags:
    - auth
    - ubuntu
```

## Примеры обновления категорий

### Категория 1: Аутентификация

```yaml
# ============================================
# 1. ОШИБКИ В УПРАВЛЕНИИ АККАУНТАМИ И АУТЕНТИФИКАЦИЕЙ
# ============================================

- name: Создание пользователей со слабыми паролями
  user:
    name: "{{ item.name }}"
    password: "{{ item.password | password_hash('sha512') }}"
    shell: /bin/bash
    groups: sudo
    append: yes
    password_expire_max: -1
  loop:
    - { name: "admin", password: "admin123" }
    - { name: "user1", password: "password123" }
    - { name: "user2", password: "123456" }
  when: ubuntu_vulnerabilities.auth_weak_passwords | default(true)
  tags:
    - auth
    - weak_passwords
    - ubuntu

- name: Отключение PAM-ограничений для паролей
  lineinfile:
    path: /etc/security/pwquality.conf
    regexp: "^{{ item.regexp }}"
    line: "{{ item.line }}"
  loop:
    - { regexp: "^minlen", line: "minlen = 1" }
    - { regexp: "^dcredit", line: "dcredit = 0" }
    # ...
  when: ubuntu_vulnerabilities.auth_no_pam_restrictions | default(true)
  tags:
    - auth
    - pam
    - ubuntu

- name: Отключение политики блокировки после неверных попыток
  lineinfile:
    path: /etc/pam.d/common-auth
    regexp: "^auth.*pam_tally2"
    state: absent
  ignore_errors: yes
  when: ubuntu_vulnerabilities.auth_no_account_lockout | default(true)
  tags:
    - auth
    - account_lockout
    - ubuntu

- name: Настройка паролей без срока действия
  shell: chage -M -1 {{ item }}
  loop:
    - admin
    - user1
    - user2
  ignore_errors: yes
  when: ubuntu_vulnerabilities.auth_no_password_expiry | default(true)
  tags:
    - auth
    - password_expiry
    - ubuntu

- name: Настройка широких sudo прав
  copy:
    content: |
      admin ALL=(ALL) NOPASSWD: ALL
      user1 ALL=(ALL) NOPASSWD: ALL
      user2 ALL=(ALL) NOPASSWD: ALL
    dest: /etc/sudoers.d/vulnerable
    mode: '0440'
  when: ubuntu_vulnerabilities.auth_wide_sudo_rights | default(true)
  tags:
    - auth
    - sudo
    - ubuntu
```

### Категория 2: SSH

```yaml
# ============================================
# 2. УЯЗВИМОСТИ ПРИ КОНФИГУРАЦИИ SSH
# ============================================

- name: Настройка SSH с небезопасными параметрами
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^{{ item.regexp }}"
    line: "{{ item.line }}"
    backup: yes
  loop:
    - { regexp: "^#?PermitRootLogin", line: "PermitRootLogin yes" }
    - { regexp: "^#?PasswordAuthentication", line: "PasswordAuthentication yes" }
    - { regexp: "^#?MaxAuthTries", line: "MaxAuthTries 1000" }
  notify: restart ssh
  when: ubuntu_vulnerabilities.ssh_password_auth | default(true) or ubuntu_vulnerabilities.ssh_root_login | default(true)
  tags:
    - ssh
    - ubuntu
```

### Категория 3: Сеть и Firewall

```yaml
# ============================================
# 3. ОШИБКИ КОНФИГУРАЦИИ СЕТИ И FIREWALL
# ============================================

- name: Отключение UFW
  ufw:
    state: disabled
  when: ubuntu_vulnerabilities.network_firewall_off | default(true)
  tags:
    - network
    - firewall
    - ubuntu

- name: Открытие небезопасных портов
  ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - 23  # Telnet
    - 21  # FTP
    - 513 # Rlogin
  when: ubuntu_vulnerabilities.network_open_ports | default(true)
  tags:
    - network
    - open_ports
    - ubuntu
```

## Автоматизация обновления

Для автоматического обновления всего playbook можно использовать скрипт или выполнить вручную по паттерну выше.

## Проверка обновления

После обновления проверьте:

```bash
# Синтаксис
ansible-playbook -i inventory.yml playbook.yml --syntax-check

# Тестовый запуск
ansible-playbook -i inventory.yml playbook.yml --check --tags "auth"

# Проверка переменных
ansible-playbook -i inventory.yml playbook.yml --list-tags
```

## Примечания

1. Используйте `| default(true)` для обратной совместимости
2. Группируйте связанные задачи под одним условием
3. Добавляйте теги для удобного управления
4. Тестируйте каждую категорию отдельно

