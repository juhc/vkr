#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Создание Proxmox cloud-init template из cloud-image (qcow2) через Proxmox API.

Использование:
  ./New-ProxmoxCloudInitTemplate.sh \
    --api-url https://pve:8006/api2/json \
    --node pve \
    --token-id "packer@pam!packer-token" \
    --token-secret "..." \
    --iso-storage local \
    --disk-storage local-lvm \
    --efi-storage local-lvm \
    --bridge vmbr0 \
    --template-name debian-cloudinit-template-uefi \
    --cloud-image-url https://...qcow2 \
    --cloud-image-filename debian-13-genericcloud-amd64.qcow2 \
    --cores 2 \
    --memory-mb 2048 \
    --ci-user ansible \
    --ssh-public-key-path ~/.ssh/id_ed25519.pub \
    --ipconfig0 "ip=dhcp" \
    [--vmid 106]

Требования:
  - bash, curl, jq
USAGE
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need curl
need jq

API_URL=""
NODE=""
TOKEN_ID=""
TOKEN_SECRET=""
ISO_STORAGE="local"
DISK_STORAGE="local-lvm"
EFI_STORAGE=""
BRIDGE="vmbr0"
TEMPLATE_NAME=""
VMID=""
CLOUD_IMAGE_URL=""
CLOUD_IMAGE_FILENAME=""
CORES="2"
MEMORY_MB="2048"
CI_USER="ansible"
SSH_PUBLIC_KEY_PATH=""
IPCONFIG0="ip=dhcp"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-url) API_URL="$2"; shift 2 ;;
    --node) NODE="$2"; shift 2 ;;
    --token-id) TOKEN_ID="$2"; shift 2 ;;
    --token-secret) TOKEN_SECRET="$2"; shift 2 ;;
    --iso-storage) ISO_STORAGE="$2"; shift 2 ;;
    --disk-storage) DISK_STORAGE="$2"; shift 2 ;;
    --efi-storage) EFI_STORAGE="$2"; shift 2 ;;
    --bridge) BRIDGE="$2"; shift 2 ;;
    --template-name) TEMPLATE_NAME="$2"; shift 2 ;;
    --vmid) VMID="$2"; shift 2 ;;
    --cloud-image-url) CLOUD_IMAGE_URL="$2"; shift 2 ;;
    --cloud-image-filename) CLOUD_IMAGE_FILENAME="$2"; shift 2 ;;
    --cores) CORES="$2"; shift 2 ;;
    --memory-mb) MEMORY_MB="$2"; shift 2 ;;
    --ci-user) CI_USER="$2"; shift 2 ;;
    --ssh-public-key-path) SSH_PUBLIC_KEY_PATH="$2"; shift 2 ;;
    --ipconfig0) IPCONFIG0="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$API_URL" || -z "$NODE" || -z "$TOKEN_ID" || -z "$TOKEN_SECRET" || -z "$TEMPLATE_NAME" || -z "$CLOUD_IMAGE_URL" || -z "$CLOUD_IMAGE_FILENAME" ]]; then
  echo "Missing required args." >&2
  usage
  exit 2
fi

normalize_api_url() {
  local u="${1%/}"
  if [[ "$u" != */api2/json ]]; then
    u="$u/api2/json"
  fi
  printf '%s' "$u"
}

API_URL="$(normalize_api_url "$API_URL")"
AUTH_HEADER="Authorization: PVEAPIToken=$TOKEN_ID=$TOKEN_SECRET"

if [[ -z "$EFI_STORAGE" ]]; then EFI_STORAGE="$DISK_STORAGE"; fi

curl_json() {
  local method="$1" url="$2"; shift 2
  if [[ "$method" == "GET" ]]; then
    curl -sSk -H "$AUTH_HEADER" "$url"
  else
    curl -sSk -H "$AUTH_HEADER" -X "$method" "$@" "$url"
  fi
}

wait_task() {
  local upid="$1"
  local enc
  enc="$(python - <<PY 2>/dev/null || true
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
"$upid")"
  if [[ -z "$enc" ]]; then
    # fallback: minimal encoding (works for most UPID)
    enc="${upid//:/%3A}"
  fi
  local url="$API_URL/nodes/$NODE/tasks/$enc/status"
  while true; do
    sleep 2
    local st
    st="$(curl_json GET "$url")"
    local status exitstatus
    status="$(echo "$st" | jq -r '.data.status // empty')"
    exitstatus="$(echo "$st" | jq -r '.data.exitstatus // empty')"
    if [[ "$status" == "stopped" ]]; then
      if [[ -n "$exitstatus" && "$exitstatus" != "OK" ]]; then
        echo "Task failed: $upid exitstatus=$exitstatus" >&2
        exit 1
      fi
      return 0
    fi
  done
}

echo "Proxmox API: $API_URL"
echo "Node      : $NODE"
echo "Template  : $TEMPLATE_NAME"

if [[ -z "${VMID:-}" ]]; then
  VMID="$(curl_json GET "$API_URL/cluster/nextid" | jq -r '.data')"
fi
echo "VMID      : $VMID"

IMPORT_VOLID="$ISO_STORAGE:import/$CLOUD_IMAGE_FILENAME"

has_volid() {
  local storage="$1" volid="$2"
  local list
  list="$(curl_json GET "$API_URL/nodes/$NODE/storage/$storage/content")"
  echo "$list" | jq -e --arg v "$volid" '.data[]? | select(.volid == $v)' >/dev/null 2>&1
}

if has_volid "$ISO_STORAGE" "$IMPORT_VOLID"; then
  echo "Cloud image already present: $IMPORT_VOLID"
else
  echo "Downloading cloud image to $IMPORT_VOLID ..."
  local_upid="$(curl_json POST "$API_URL/nodes/$NODE/storage/$ISO_STORAGE/download-url" \
    --data-urlencode "url=$CLOUD_IMAGE_URL" \
    --data-urlencode "content=import" \
    --data-urlencode "filename=$CLOUD_IMAGE_FILENAME" \
    | jq -r '.data')"
  if [[ -z "${local_upid:-}" || "$local_upid" == "null" ]]; then
    echo "download-url did not return UPID. Проверьте storage (directory) и content=import." >&2
    exit 1
  fi
  wait_task "$local_upid"
  echo "Downloaded: $IMPORT_VOLID"
fi

echo "Creating VM (no disk)..."
upid_create="$(curl_json POST "$API_URL/nodes/$NODE/qemu" \
  --data-urlencode "vmid=$VMID" \
  --data-urlencode "name=$TEMPLATE_NAME" \
  --data-urlencode "cores=$CORES" \
  --data-urlencode "memory=$MEMORY_MB" \
  --data-urlencode "agent=1" \
  --data-urlencode "scsihw=virtio-scsi-pci" \
  --data-urlencode "net0=virtio,bridge=$BRIDGE" \
  --data-urlencode "ostype=l26" \
  --data-urlencode "bios=ovmf" \
  --data-urlencode "machine=q35" \
  | jq -r '.data // empty')"
if [[ -n "${upid_create:-}" ]]; then wait_task "$upid_create"; fi

echo "Configuring disks/cloud-init..."
scsi0="$DISK_STORAGE:0,import-from=$IMPORT_VOLID"
ide2="$DISK_STORAGE:cloudinit"
efidisk0="$EFI_STORAGE:0,efitype=4m,pre-enrolled-keys=1"

upid_cfg="$(curl_json POST "$API_URL/nodes/$NODE/qemu/$VMID/config" \
  --data-urlencode "scsi0=$scsi0" \
  --data-urlencode "ide2=$ide2" \
  --data-urlencode "efidisk0=$efidisk0" \
  --data-urlencode "boot=order=scsi0;net0" \
  --data-urlencode "bootdisk=scsi0" \
  --data-urlencode "serial0=socket" \
  --data-urlencode "vga=std" \
  --data-urlencode "ipconfig0=$IPCONFIG0" \
  --data-urlencode "ciuser=$CI_USER" \
  | jq -r '.data // empty')"
if [[ -n "${upid_cfg:-}" ]]; then wait_task "$upid_cfg"; fi

if [[ -n "$SSH_PUBLIC_KEY_PATH" && -f "$SSH_PUBLIC_KEY_PATH" ]]; then
  key="$(cat "$SSH_PUBLIC_KEY_PATH" | tr -d '\r' | tr -d '\n')"
  upid_key="$(curl_json POST "$API_URL/nodes/$NODE/qemu/$VMID/config" \
    --data-urlencode "sshkeys=$key" \
    | jq -r '.data // empty')"
  if [[ -n "${upid_key:-}" ]]; then wait_task "$upid_key"; fi
  echo "SSH key applied"
fi

echo "Converting to template..."
upid_tpl="$(curl_json POST "$API_URL/nodes/$NODE/qemu/$VMID/template" | jq -r '.data // empty')"
if [[ -n "${upid_tpl:-}" ]]; then wait_task "$upid_tpl"; fi

echo "Template ready: $TEMPLATE_NAME (VMID $VMID)"

