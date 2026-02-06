# Terraform модуль виртуальной машины (libvirt)

Этот модуль создает виртуальные машины на основе **libvirt/KVM**.
В текущих стендах проекта используется **Proxmox** (см. `stands/*/infrastructure/terraform/`), поэтому модуль можно считать legacy/опциональным для альтернативной среды.

## Использование

```hcl
module "vm" {
  source = "../../terraform/modules/vm"
  
  vm_name        = "web-server"
  cpu            = 2
  memory         = 4096
  disk_size      = 50
  network_name   = "my-network"
  ip_address     = "192.168.1.10"
  gateway        = "192.168.1.1"
  dns_servers    = ["8.8.8.8", "8.8.4.4"]
  hostname       = "web-server"
  domain         = "example.local"
  base_image_path = "/var/lib/libvirt/images/ubuntu-20.04.img"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

## Переменные

| Переменная | Описание | Тип | По умолчанию | Обязательно |
|------------|----------|-----|--------------|-------------|
| vm_name | Имя виртуальной машины | string | - | Да |
| vm_count | Количество виртуальных машин | number | 1 | Нет |
| cpu | Количество CPU | number | 2 | Нет |
| memory | Объем памяти в MB | number | 4096 | Нет |
| disk_size | Размер диска в GB | number | 50 | Нет |
| network_name | Имя сети libvirt | string | - | Да |
| ip_address | IP адрес (пустой для DHCP) | string | "" | Нет |
| hostname | Имя хоста | string | "" | Нет |
| base_image_path | Путь к базовому образу | string | - | Да |

## Выводы

| Вывод | Описание |
|-------|----------|
| vm_ids | ID виртуальных машин |
| vm_names | Имена виртуальных машин |
| vm_ip_addresses | IP адреса виртуальных машин |
| vm_macs | MAC адреса виртуальных машин |

## Требования

- libvirt провайдер для Terraform
- Базовый образ Ubuntu Cloud Image
- Настроенная сеть libvirt

