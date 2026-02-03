# vkr_ad_join

Роль присоединяет машины **Windows** и **Linux** к домену **Active Directory** и (опционально) настраивает DNS на Domain Controller перед join.

## Переменные

- `vkr_ad_domain_name` (string, required): например `training.local`
- `vkr_ad_dc_ip` (string, required): IP DC (DNS)
- `vkr_ad_join_user` (string, required): например `Administrator@training.local`
- `vkr_ad_join_password` (string, required, secret): пароль для join (через Ansible Vault)
- `vkr_ad_configure_dns` (bool, default `true`): выставлять DNS на `vkr_ad_dc_ip` перед join

## Использование

Подключите роль в playbook целевой машины:

```yaml
- ansible.builtin.import_role:
    name: vkr_ad_join
```

И задайте переменные в `group_vars/all/ad.yml` (см. `ad.yml.example` в стендах).
