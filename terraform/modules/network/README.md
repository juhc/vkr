# Terraform модуль сети

Этот модуль создает виртуальные сети для libvirt/KVM.

## Использование

```hcl
module "network" {
  source = "../../terraform/modules/network"
  
  network_name = "my-network"
  network_cidr = "192.168.1.0/24"
  dhcp_enabled = true
  dhcp_start   = "192.168.1.100"
  dhcp_end     = "192.168.1.200"
}
```

## Переменные

| Переменная | Описание | Тип | По умолчанию | Обязательно |
|------------|----------|-----|--------------|-------------|
| network_name | Имя сети | string | - | Да |
| network_cidr | CIDR сети | string | - | Да |
| dhcp_enabled | Включить DHCP | bool | true | Нет |
| dhcp_start | Начальный IP для DHCP | string | "" | Нет |
| dhcp_end | Конечный IP для DHCP | string | "" | Нет |

## Выводы

| Вывод | Описание |
|-------|----------|
| network_id | ID сети |
| network_name | Имя сети |
| network_bridge | Имя bridge интерфейса |

