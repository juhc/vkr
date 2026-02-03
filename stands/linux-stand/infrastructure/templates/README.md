# Packer для Linux стенда (Proxmox)

Здесь лежат **Packer-шаблоны Linux** для `linux-stand`.  
Windows-шаблоны находятся отдельно в `windows-stand`.

## Что внутри (cloud-init)

Основной путь для Linux — **cloud-image (qcow2) + cloud-init**:

- `cloudinit/` — переменные и обёртки запуска (server/client)
- `scripts/New-ProxmoxCloudInitTemplate.ps1` — создаёт Proxmox template:
  - скачивает cloud image в Proxmox storage (`download-url`)
  - создаёт VM
  - импортирует qcow2 как диск VM
  - добавляет cloud-init drive
  - конвертирует VM в template

> Старые шаблоны на ISO/preseed удалены — оставляем только cloud-init, чтобы не путаться.

## Как создать template (cloud-init)

1) Создайте/заполните:
   - `variables.common.pkrvars.hcl` из `variables.common.pkrvars.hcl.example`
   - `variables.secrets.pkrvars.hcl` из `variables.secrets.pkrvars.hcl.example`

2) Создайте var-файлы cloud-init (по одному на шаблон):
   - `cloudinit/variables.cloudinit.linux-server.pkrvars.hcl` из `cloudinit/variables.cloudinit.linux-server.pkrvars.hcl.example`
   - `cloudinit/variables.cloudinit.linux-client.pkrvars.hcl` из `cloudinit/variables.cloudinit.linux-client.pkrvars.hcl.example`

В них задаются:
- `template_name` (имя template в Proxmox)
- `cloud_image_url` / `cloud_image_filename` (qcow2 cloud-image)
- ресурсы (CPU/RAM)
- дефолты cloud-init (`ci_user`, `ssh_public_key_path`, `ipconfig0`)

3) Запуск:

```powershell
cd D:\zxc\vkr\stands\linux-stand\infrastructure\templates
.\cloudinit\create-templates.ps1
```

Linux/macOS (bash):

```bash
cd stands/linux-stand/infrastructure/templates
./cloudinit/create-templates.sh
```

Или по одному (server/client):

```powershell
cd D:\zxc\vkr\stands\linux-stand\infrastructure\templates
.\cloudinit\create-template.ps1 -VarsFile .\cloudinit\variables.cloudinit.linux-server.pkrvars.hcl
```

```bash
cd stands/linux-stand/infrastructure/templates
./cloudinit/create-template.sh -f ./cloudinit/variables.cloudinit.linux-server.pkrvars.hcl
```

