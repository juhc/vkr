# Кастомный ISO для автоустановки Windows (подход из статьи VirtualizationHowto)

Вы попросили сделать как в статье: Windows ISO **модифицируется вручную**, а Packer просто использует готовый ISO.

Источник: [Windows Server 2025 Proxmox Packer Build Fully Automated](https://www.virtualizationhowto.com/2024/11/windows-server-2025-proxmox-packer-build-fully-automated/)

## Что нужно положить в корень ISO

- **`autounattend.xml`** — файл ответов (именно в корень ISO)
- **`$WinpeDriver$`** — папка с драйверами VirtIO (как в статье)
  - внутри должны быть `.inf/.sys/.cat` для диска и сети
- (опционально) **`setup.ps1`** — если вы хотите запускать PowerShell на первом входе (по статье)

## Важные моменты

- **Кодировка `autounattend.xml`**: если файл сохранён как UTF‑16LE (с BOM), то в шапке XML должна быть
  `encoding="utf-16"`. Несовпадение (например BOM UTF‑16, а в шапке `utf-8`) часто ломает автоустановку
  и даёт “внутреннюю ошибку программы установки”.

- Если в `autounattend.xml` есть строка типа `wim://server/share/install.wim...` (например `cpi:offlineImage`) — **удаляйте**: часто из‑за неё Setup пишет “компонент или файл не существует”.
- Для UEFI/OVMF (мы включили в Packer `bios = "ovmf"`): ваш `autounattend.xml` должен разметить диск как GPT/EFI (если вы используете UEFI-разметку).
- Драйверы: при наличии папки **`$WinpeDriver$`** Windows Setup автоматически подхватывает драйверы в WinPE.

## Как собрать ISO на Windows (ADK / oscdimg)

1) Установите **Windows ADK** и компонент **Deployment Tools** (как в статье).

2) Смонтируйте оригинальный ISO Windows и скопируйте его содержимое в папку, например:

- `D:\iso\win-src\`

3) В `D:\iso\win-src\` добавьте:

- `autounattend.xml`
- `$WinpeDriver$\` (папка с драйверами)
- (опционально) `setup.ps1`

4) В “Deployment and Imaging Tools Environment” соберите ISO:

Пример (UEFI + BIOS):

```bat
oscdimg -m -o -u2 -udfver102 ^
  -bootdata:2#p0,e,bD:\iso\win-src\boot\etfsboot.com#pEF,e,bD:\iso\win-src\efi\microsoft\boot\efisys.bin ^
  D:\iso\win-src D:\iso\Windows10_64bit_unattend.iso
```

После этого загрузите `Windows10_64bit_unattend.iso` в Proxmox (`local:iso/`).

## Как пересобрать ISO после правок

См. `..\scripts\CREATE_ISO_MANUAL.md` и скрипт `..\scripts\rebuild-custom-iso.ps1`.

## Как это связано с Packer

В `variables.pkrvars.hcl` укажите:

- `iso_file = "local:iso/Windows10_64bit_unattend.iso"`

Packer больше **не создаёт дополнительный ISO** и не использует `cd_files`.

