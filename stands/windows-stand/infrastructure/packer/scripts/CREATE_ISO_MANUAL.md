# Пересборка кастомных Windows ISO (после правок autounattend / OEM scripts / драйверов)

## Что такое «исходники ISO»

Это **папка с распакованным ISO**, например `D:\iso\win10\` (локально на вашей машине).

Внутри должны быть стандартные файлы Windows ISO (`boot\`, `efi\`, `sources\` и т.д.), плюс ваши добавления:

- `autounattend.xml` в корне папки
- `$WinpeDriver$` в корне папки (VirtIO драйверы для WinPE: диск+сеть)
- `sources\$OEM$\$$\Setup\Scripts\SetupComplete.cmd`
- `sources\$OEM$\$$\Setup\Scripts\setup.ps1`

## Как пересобрать ISO (Windows / PowerShell)

Нужен **Windows ADK** (oscidmg.exe).

### Пример для Win10 (из папки iso/win10)

```powershell
cd D:\zxc\vkr\stands\windows-stand\infrastructure\packer
.\scripts\rebuild-custom-iso.ps1 `
  -SourceDir D:\iso\win10 `
  -OutputIso D:\iso\Windows10_64bit_unattend_custom.iso
```

Скрипт выведет SHA256 нового ISO.

## Дальше

1) Загрузите новый ISO в Proxmox (`local:iso/...`)
2) Обновите `iso_file` в нужном `*/variables.pkrvars.hcl`
3) Запустите `packer build`
