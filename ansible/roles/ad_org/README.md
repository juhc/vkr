# ad_org

Роль решает “организационную” часть AD для стенда:

- создаёт OU структуру (например `OU=Training` и `OU=<stand>` внутри неё),
- создаёт security‑группу компьютеров стенда,
- перемещает **компьютерные аккаунты** ВМ стенда в нужную OU,
- линкует все GPO с заданным префиксом (например `training-ad.gpo.*`) к OU стенда,
- настраивает security filtering: **Apply** только для группы компьютеров стенда.

Это нужно, чтобы `ad.gpo.*` уязвимости **реально применялись** к нужным ВМ и не затрагивали другие стенды.

## Переменные

- `ad_org_enabled` (bool, default `true`)
- `ad_training_ou` (string, default `Training`)
- `ad_stand_ou` (string, default `Stand-01`)
- `ad_stand_id` (string, default `stand-01`) — используется для имени группы
- `ad_stand_computers` (list[string]) — список имён компьютерных аккаунтов (COMPUTERNAME) в домене
- `ad_gpo_prefix` (string, default `training-ad.gpo.`)

## Использование

Обычно вызывается на `domain_controller` после того, как клиенты уже сделали domain join.

```yaml
- ansible.builtin.import_role:
    name: ad_org
```

