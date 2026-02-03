#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Использование:
  ./Invoke-PackerBuildWithNextId.sh <target> [--common <path>] [--secrets <path>] [--os <path>]

target:
  windows-10 | windows-11 | windows-server | domain-controller

По умолчанию:
  --common  ../variables.common.pkrvars.hcl
  --secrets ../variables.secrets.pkrvars.hcl
  --os      ../<target>/variables.pkrvars.hcl

Требования:
  - bash, curl, jq, packer
USAGE
}

if [[ $# -lt 1 ]]; then usage; exit 2; fi

TARGET="$1"; shift || true
case "$TARGET" in
  windows-10|windows-11|windows-server|domain-controller) ;;
  *) echo "Unknown target: $TARGET" >&2; usage; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

COMMON_VARS="$BASE_DIR/variables.common.pkrvars.hcl"
SECRETS_VARS="$BASE_DIR/variables.secrets.pkrvars.hcl"
OS_VARS="$BASE_DIR/$TARGET/variables.pkrvars.hcl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --common) COMMON_VARS="$2"; shift 2 ;;
    --secrets) SECRETS_VARS="$2"; shift 2 ;;
    --os) OS_VARS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

for f in "$COMMON_VARS" "$SECRETS_VARS" "$OS_VARS"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing var-file: $f" >&2
    exit 1
  fi
done

get_hcl_value() {
  local file="$1" key="$2"
  # key = "value"  OR  key = value
  awk -v k="$key" '
    BEGIN { FS="=" }
    /^[[:space:]]*#/ { next }
    $0 ~ "^[[:space:]]*"k"[[:space:]]*=" {
      sub(/^[[:space:]]*[^=]+=[[:space:]]*/, "", $0)
      sub(/[[:space:]]*(#.*)?$/, "", $0)
      gsub(/^"|"$/, "", $0)
      gsub(/^'\''|'\''$/, "", $0)
      print $0
      exit
    }
  ' "$file"
}

API_URL="$(get_hcl_value "$COMMON_VARS" "proxmox_api_url")"
TOKEN_ID="$(get_hcl_value "$SECRETS_VARS" "proxmox_api_token_id")"
TOKEN_SECRET="$(get_hcl_value "$SECRETS_VARS" "proxmox_api_token_secret")"

if [[ -z "${API_URL:-}" ]]; then echo "Missing proxmox_api_url in $COMMON_VARS" >&2; exit 1; fi
if [[ -z "${TOKEN_ID:-}" || -z "${TOKEN_SECRET:-}" ]]; then echo "Missing proxmox_api_token_id/proxmox_api_token_secret in $SECRETS_VARS" >&2; exit 1; fi

API_URL="${API_URL%/}"
NEXTID_URL="$API_URL/cluster/nextid"
AUTH="PVEAPIToken=$TOKEN_ID=$TOKEN_SECRET"

echo "Proxmox API: $API_URL"
echo "Target     : $TARGET"

VMID="$(curl -sSk -H "Authorization: $AUTH" "$NEXTID_URL" | jq -r '.data')"
if [[ -z "${VMID:-}" || "${VMID}" == "null" ]]; then
  echo "Failed to get nextid from $NEXTID_URL" >&2
  exit 1
fi
echo "Свободный VMID: $VMID"

TARGET_DIR="$BASE_DIR/$TARGET"
pushd "$TARGET_DIR" >/dev/null
packer init .
packer build \
  -var-file="../$(basename "$COMMON_VARS")" \
  -var-file="../$(basename "$SECRETS_VARS")" \
  -var-file="variables.pkrvars.hcl" \
  -var "vm_id=$VMID" \
  .
popd >/dev/null

