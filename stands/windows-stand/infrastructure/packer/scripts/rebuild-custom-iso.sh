#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Пересборка Windows ISO из распакованной директории.

Зачем:
  - если вы модифицируете ISO "вручную" (autounattend.xml, $WinpeDriver$, $OEM$),
    и хотите собирать ISO не только на Windows (oscdimg), но и на Linux/macOS.

Использование:
  ./rebuild-custom-iso.sh --src ./iso/win10 --out ./Windows10_custom.iso [--label WIN10_CUSTOM]

Требования:
  - xorriso (рекомендуется) ИЛИ mkisofs/genisoimage

Важно:
  - Скрипт ожидает стандартную структуру Windows ISO:
    boot/etfsboot.com и efi/microsoft/boot/efisys.bin
USAGE
}

SRC=""
OUT=""
LABEL="WIN_CUSTOM"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --src) SRC="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$SRC" || -z "$OUT" ]]; then usage; exit 2; fi
if [[ ! -d "$SRC" ]]; then echo "SRC dir not found: $SRC" >&2; exit 1; fi

BIOS_BOOT="$SRC/boot/etfsboot.com"
EFI_BOOT="$SRC/efi/microsoft/boot/efisys.bin"

if [[ ! -f "$BIOS_BOOT" ]]; then echo "Missing BIOS boot image: $BIOS_BOOT" >&2; exit 1; fi
if [[ ! -f "$EFI_BOOT" ]]; then echo "Missing EFI boot image: $EFI_BOOT" >&2; exit 1; fi

if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs \
    -iso-level 4 \
    -J -joliet-long -relaxed-filenames \
    -udf -udf-version 2.01 \
    -V "$LABEL" \
    -b "boot/etfsboot.com" \
      -no-emul-boot -boot-load-size 8 -boot-info-table \
    -eltorito-alt-boot \
    -eltorito-platform efi \
    -b "efi/microsoft/boot/efisys.bin" \
      -no-emul-boot \
    -o "$OUT" \
    "$SRC"
  echo "ISO created: $OUT"
  exit 0
fi

if command -v genisoimage >/dev/null 2>&1; then
  genisoimage \
    -iso-level 4 \
    -J -joliet-long -relaxed-filenames \
    -udf \
    -V "$LABEL" \
    -b "boot/etfsboot.com" \
      -no-emul-boot -boot-load-size 8 -boot-info-table \
    -eltorito-alt-boot \
    -eltorito-platform efi \
    -b "efi/microsoft/boot/efisys.bin" \
      -no-emul-boot \
    -o "$OUT" \
    "$SRC"
  echo "ISO created: $OUT"
  exit 0
fi

if command -v mkisofs >/dev/null 2>&1; then
  mkisofs \
    -iso-level 4 \
    -J -joliet-long -relaxed-filenames \
    -udf \
    -V "$LABEL" \
    -b "boot/etfsboot.com" \
      -no-emul-boot -boot-load-size 8 -boot-info-table \
    -eltorito-alt-boot \
    -eltorito-platform efi \
    -b "efi/microsoft/boot/efisys.bin" \
      -no-emul-boot \
    -o "$OUT" \
    "$SRC"
  echo "ISO created: $OUT"
  exit 0
fi

echo "No ISO tool found. Install xorriso (preferred) or genisoimage/mkisofs." >&2
exit 1

