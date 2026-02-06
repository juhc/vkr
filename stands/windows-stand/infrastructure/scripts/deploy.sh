#!/usr/bin/env bash
# Полный деплой Windows стенда: Packer templates -> Terraform -> Ansible
set -euo pipefail

usage() {
  cat <<'USAGE'
Использование:
  ./deploy.sh [--skip-templates] [--skip-terraform] [--skip-ansible]

По умолчанию выполняет всё:
  1) Создание Windows templates через Packer (если var-files подготовлены)
  2) Terraform apply (windows-10 + windows-server + domain-controller)
  3) Ansible (пользователи/группы + уязвимости)

Требования:
  - terraform, ansible-playbook
  - для templates: packer
USAGE
}

DO_TEMPLATES=1
DO_TERRAFORM=1
DO_ANSIBLE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-templates) DO_TEMPLATES=0; shift ;;
    --skip-terraform) DO_TERRAFORM=0; shift ;;
    --skip-ansible) DO_ANSIBLE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need_file() { [[ -f "$1" ]] || { echo "Missing file: $1" >&2; exit 1; }; }
warn() { echo "WARN: $1" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANS_DIR="$SCENARIO_ROOT/infrastructure/ansible"
TF_DIR="$SCENARIO_ROOT/infrastructure/terraform"
INV_SCRIPT="$SCRIPT_DIR/generate_inventory.py"

echo "=========================================="
echo "Деплой Windows стенда"
echo "  root: $SCENARIO_ROOT"
echo "=========================================="

if [[ $DO_TEMPLATES -eq 1 ]]; then need packer; fi
if [[ $DO_TERRAFORM -eq 1 ]]; then need terraform; fi
if [[ $DO_ANSIBLE -eq 1 ]]; then need ansible-playbook; need python3; fi

wait_for_ssh() {
  local host="$1" port="${2:-22}" timeout="${3:-600}"
  local start
  start="$(date +%s 2>/dev/null || echo 0)"
  while true; do
    if command -v nc >/dev/null 2>&1; then
      nc -z "$host" "$port" >/dev/null 2>&1 && return 0
    else
      (echo >/dev/tcp/"$host"/"$port") >/dev/null 2>&1 && return 0 || true
    fi
    sleep 5
    if [[ "$start" != "0" ]]; then
      local now; now="$(date +%s)"
      if (( now - start > timeout )); then
        echo "Timeout waiting for $host:$port" >&2
        return 1
      fi
    fi
  done
}

# IP адреса можно переопределять через окружение (для переносимости стенда)
WINDOWS_WS_IP="${WINDOWS_WS_IP:-192.168.101.10}"
WINDOWS_SERVER_IP="${WINDOWS_SERVER_IP:-192.168.101.20}"
DC_IP="${DC_IP:-192.168.101.30}"

if [[ $DO_TEMPLATES -eq 1 ]]; then
  echo ""
  echo "== Packer templates =="
  PKR_DIR="$SCENARIO_ROOT/infrastructure/packer"
  if [[ ! -d "$PKR_DIR" ]]; then
    echo "Packer dir not found: $PKR_DIR" >&2
    exit 1
  fi

  if [[ -f "$PKR_DIR/variables.common.pkrvars.hcl" && -f "$PKR_DIR/variables.secrets.pkrvars.hcl" ]]; then
    chmod +x "$PKR_DIR/build-example.sh" >/dev/null 2>&1 || true
    (cd "$PKR_DIR" && ./build-example.sh)
  else
    echo "Пропуск templates: создайте variables.common.pkrvars.hcl и variables.secrets.pkrvars.hcl в $PKR_DIR (из *.example)."
  fi
fi

if [[ $DO_TERRAFORM -eq 1 ]]; then
  echo ""
  echo "== Terraform =="
  need_file "$TF_DIR/windows-10/terraform.tfvars"
  need_file "$TF_DIR/windows-server/terraform.tfvars"
  need_file "$TF_DIR/domain-controller/terraform.tfvars"
  for comp in windows-10 windows-server domain-controller; do
    if [[ -d "$TF_DIR/$comp" ]]; then
      echo "-- terraform apply: $comp"
      (cd "$TF_DIR/$comp" && terraform init -input=false && terraform apply -input=false -auto-approve)
    fi
  done
fi

if [[ $DO_ANSIBLE -eq 1 ]]; then
  echo ""
  echo "== Ansible =="
  need_file "$INV_SCRIPT"
  if [[ -z "${ANSIBLE_PASSWORD:-}" ]]; then
    warn "ANSIBLE_PASSWORD is empty; inventory will contain placeholder."
  fi

  # Генерация inventory из Terraform outputs
  eval "$(python3 "$INV_SCRIPT" \
    --windows-10-dir "$TF_DIR/windows-10" \
    --windows-server-dir "$TF_DIR/windows-server" \
    --domain-controller-dir "$TF_DIR/domain-controller" \
    --inventory-path "$ANS_DIR/inventory.yml" \
    --print-env)"

  echo "Waiting for SSH..."
  wait_for_ssh "$WINDOWS_WS_IP" 22 900 || true
  wait_for_ssh "$WINDOWS_SERVER_IP" 22 900 || true
  wait_for_ssh "$DC_IP" 22 900 || true

  echo "-- windows-10 playbook"
  echo "-- domain-controller playbook"
  (cd "$ANS_DIR" && ansible-playbook domain-controller/playbook.yml)
  echo "-- windows-10 playbook"
  (cd "$ANS_DIR" && ansible-playbook windows-10/playbook.yml)
  echo "-- windows-server playbook"
  (cd "$ANS_DIR" && ansible-playbook windows-server/playbook.yml)
  echo "-- domain-controller playbook (post-join, OU/GPO scope)"
  (cd "$ANS_DIR" && ansible-playbook domain-controller/playbook.yml)
fi

echo ""
echo "=========================================="
echo "Готово."
echo "IP:"
echo "  - Windows WS:   $WINDOWS_WS_IP"
echo "  - Win Server:   $WINDOWS_SERVER_IP"
echo "  - DC:           $DC_IP"
echo "=========================================="
