#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Создать один cloud-init template (Linux) из vars-файла.

Использование:
  ./create-template.sh -f ./variables.cloudinit.linux-server.pkrvars.hcl

Требования:
  - bash, curl, jq
USAGE
}

if [[ $# -lt 2 ]]; then usage; exit 2; fi

VARS_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--vars-file) VARS_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$VARS_FILE" || ! -f "$VARS_FILE" ]]; then
  echo "Vars file not found: $VARS_FILE" >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON="$BASE_DIR/variables.common.pkrvars.hcl"
SECRETS="$BASE_DIR/variables.secrets.pkrvars.hcl"

if [[ ! -f "$COMMON" ]]; then echo "Missing $COMMON (create from *.example)" >&2; exit 1; fi
if [[ ! -f "$SECRETS" ]]; then echo "Missing $SECRETS (create from *.example)" >&2; exit 1; fi

get_hcl_value() {
  local file="$1" key="$2"
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

api_url="$(get_hcl_value "$COMMON" proxmox_api_url)"
node="$(get_hcl_value "$COMMON" proxmox_node)"
iso_pool="$(get_hcl_value "$COMMON" iso_storage_pool)"
disk_pool="$(get_hcl_value "$COMMON" storage_pool)"
efi_pool="$(get_hcl_value "$COMMON" efi_storage_pool)"
bridge="$(get_hcl_value "$COMMON" proxmox_bridge)"

token_id="$(get_hcl_value "$SECRETS" proxmox_api_token_id)"
token_secret="$(get_hcl_value "$SECRETS" proxmox_api_token_secret)"

template_name="$(get_hcl_value "$VARS_FILE" template_name)"
img_url="$(get_hcl_value "$VARS_FILE" cloud_image_url)"
img_file="$(get_hcl_value "$VARS_FILE" cloud_image_filename)"
cores="$(get_hcl_value "$VARS_FILE" cpu_cores)"
mem="$(get_hcl_value "$VARS_FILE" memory_mb)"
ci_user="$(get_hcl_value "$VARS_FILE" ci_user)"
ssh_key_path="$(get_hcl_value "$VARS_FILE" ssh_public_key_path)"
ipcfg="$(get_hcl_value "$VARS_FILE" ipconfig0)"

SCRIPT="$BASE_DIR/scripts/New-ProxmoxCloudInitTemplate.sh"
chmod +x "$SCRIPT" >/dev/null 2>&1 || true

"$SCRIPT" \
  --api-url "$api_url" \
  --node "$node" \
  --token-id "$token_id" \
  --token-secret "$token_secret" \
  --iso-storage "${iso_pool:-local}" \
  --disk-storage "${disk_pool:-local-lvm}" \
  --efi-storage "${efi_pool:-}" \
  --bridge "${bridge:-vmbr0}" \
  --template-name "$template_name" \
  --cloud-image-url "$img_url" \
  --cloud-image-filename "$img_file" \
  --cores "${cores:-2}" \
  --memory-mb "${mem:-2048}" \
  --ci-user "${ci_user:-ansible}" \
  --ssh-public-key-path "${ssh_key_path:-}" \
  --ipconfig0 "${ipcfg:-ip=dhcp}"

