#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Создание нового стенда на основе шаблона.

Пример:
  ./tools/create-stand.sh \
    --base stands/linux-stand \
    --name linux-stand-02 \
    --stand-id stand-02 \
    --subnet 192.168.103.0/24 \
    --pve-user student01@pve \
    --pve-role StudentVM

Параметры:
  --base     Базовый стенд (stands/linux-stand или stands/windows-stand)
  --name     Имя нового каталога стенда
  --stand-id Префикс/ID стенда (опционально; по умолчанию = --name)
  --subnet   Подсеть в формате CIDR (например 192.168.103.0/24)
  --pve-user Пользователь Proxmox для ACL (по умолчанию student01@pve)
  --pve-role Роль Proxmox для ACL (по умолчанию StudentVM)
USAGE
}

BASE=""
NAME=""
STAND_ID=""
SUBNET=""
PVE_USER=""
PVE_ROLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --stand-id) STAND_ID="$2"; shift 2 ;;
    --subnet) SUBNET="$2"; shift 2 ;;
    --pve-user) PVE_USER="$2"; shift 2 ;;
    --pve-role) PVE_ROLE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$BASE" || -z "$NAME" || -z "$SUBNET" ]]; then
  usage
  exit 2
fi

if [[ -z "$STAND_ID" ]]; then
  STAND_ID="$NAME"
fi

python3 "tools/create_stand.py" \
  --base "$BASE" \
  --name "$NAME" \
  --stand-id "$STAND_ID" \
  --subnet "$SUBNET" \
  ${PVE_USER:+--pve-user "$PVE_USER"} \
  ${PVE_ROLE:+--pve-role "$PVE_ROLE"}
