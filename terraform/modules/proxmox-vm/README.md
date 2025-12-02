# Модуль Terraform для создания ВМ в Proxmox

Этот модуль создает виртуальные машины в Proxmox VE используя шаблоны.

## Требования

- Proxmox VE 6.0 или новее
- Terraform 1.0+
- Провайдер Proxmox (`telmate/proxmox`)

## Использование

```hcl
module "web_server" {
  source = "../../terraform/modules/proxmox-vm"
  
  vm_name      = "web-server"
  target_node  = "proxmox-node-1"
  template_name = "ubuntu-20.04-template"
  
  cpu    = 2
  memory = 4096
  disk_size = "50G"
  disk_storage = "local-lvm"
  
  network_bridge = "vmbr0"
  ip_address     = "192.168.20.20/24"
  gateway        = "192.168.20.1"
  
  hostname = "web-server"
  domain   = "internetplus.local"
  
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

## Переменные

| Переменная | Описание | Тип | По умолчанию |
|-----------|----------|-----|--------------|
| `vm_name` | Имя виртуальной машины | string | - |
| `target_node` | Узел Proxmox | string | - |
| `template_name` | Имя шаблона | string | - |
| `cpu` | Количество CPU | number | 2 |
| `memory` | Память в MB | number | 4096 |
| `disk_size` | Размер диска | string | "50G" |
| `disk_storage` | Хранилище | string | "local-lvm" |
| `network_bridge` | Сетевой мост | string | "vmbr0" |
| `ip_address` | IP адрес (CIDR) | string | "" |
| `gateway` | Шлюз | string | "" |
| `hostname` | Имя хоста | string | "" |
| `ssh_public_key` | SSH ключ | string | "" |

## Подготовка шаблона

Перед использованием модуля необходимо создать шаблон в Proxmox:

1. Создайте ВМ с Ubuntu Cloud Image
2. Настройте cloud-init
3. Преобразуйте в шаблон через веб-интерфейс Proxmox

