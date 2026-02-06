#!/usr/bin/env bash
# Полный деплой Linux стенда: templates (cloud-init) -> Terraform -> Ansible
set -euo pipefail

usage() {
  cat <<'USAGE'
Использование:
  ./deploy.sh [--skip-templates] [--skip-terraform] [--skip-ansible]

По умолчанию выполняет всё:
  1) Создание cloud-init templates (если vars-файлы подготовлены)
  2) Terraform apply (linux-ws + linux-server)
  3) Ansible (пользователи/группы + уязвимости)

Требования:
  - terraform, ansible-playbook
  - для templates: bash (linux/macOS) или PowerShell-скрипт запускается вручную
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
echo "Деплой Linux стенда"
echo "  root: $SCENARIO_ROOT"
echo "=========================================="

if [[ $DO_TERRAFORM -eq 1 ]]; then need terraform; fi
if [[ $DO_ANSIBLE -eq 1 ]]; then need ansible-playbook; need python3; fi

wait_for_ssh() {
  local host="$1" port="${2:-22}" timeout="${3:-300}"
  local start
  start="$(date +%s 2>/dev/null || echo 0)"
  while true; do
    if command -v nc >/dev/null 2>&1; then
      nc -z "$host" "$port" >/dev/null 2>&1 && return 0
    else
      (echo >/dev/tcp/"$host"/"$port") >/dev/null 2>&1 && return 0 || true
    fi
    sleep 3
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
LINUX_WS_IP="${LINUX_WS_IP:-192.168.102.10}"
LINUX_SERVER_IP="${LINUX_SERVER_IP:-192.168.102.20}"

if [[ $DO_TEMPLATES -eq 1 ]]; then
  echo ""
  echo "== Templates (cloud-init) =="
  TPL_DIR="$SCENARIO_ROOT/infrastructure/templates"
  if [[ ! -d "$TPL_DIR" ]]; then
    echo "Templates dir not found: $TPL_DIR" >&2
    exit 1
  fi
  # vars-файлы создаются пользователем локально; если их нет — просто пропускаем с подсказкой
  if [[ -f "$TPL_DIR/variables.common.pkrvars.hcl" && -f "$TPL_DIR/variables.secrets.pkrvars.hcl" ]]; then
    if [[ -f "$TPL_DIR/cloudinit/variables.cloudinit.linux-server.pkrvars.hcl" && -f "$TPL_DIR/cloudinit/variables.cloudinit.linux-client.pkrvars.hcl" ]]; then
      chmod +x "$TPL_DIR/cloudinit/create-templates.sh" >/dev/null 2>&1 || true
      (cd "$TPL_DIR" && ./cloudinit/create-templates.sh)
    else
      echo "Пропуск templates: создайте cloudinit vars-файлы из *.example в $TPL_DIR/cloudinit/."
    fi
  else
    echo "Пропуск templates: создайте variables.common.pkrvars.hcl и variables.secrets.pkrvars.hcl в $TPL_DIR (из *.example)."
  fi
fi

if [[ $DO_TERRAFORM -eq 1 ]]; then
  echo ""
  echo "== Terraform =="
  need_file "$TF_DIR/linux-ws/terraform.tfvars"
  need_file "$TF_DIR/linux-server/terraform.tfvars"
  for comp in linux-ws linux-server; do
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
  if [[ ! -f "${ANSIBLE_KEY:-$HOME/.ssh/id_ed25519}" ]]; then
    warn "SSH key not found: ${ANSIBLE_KEY:-$HOME/.ssh/id_ed25519}"
  fi

  # Генерация inventory из Terraform outputs
  eval "$(python3 "$INV_SCRIPT" \
    --linux-ws-dir "$TF_DIR/linux-ws" \
    --linux-server-dir "$TF_DIR/linux-server" \
    --inventory-path "$ANS_DIR/inventory.yml" \
    --print-env)"

  # Ждём SSH (если IP дефолтные) — иначе Ansible сразу упадёт.
  echo "Waiting for SSH..."
  wait_for_ssh "$LINUX_WS_IP" 22 300 || true
  wait_for_ssh "$LINUX_SERVER_IP" 22 300 || true

  echo "-- linux-ws playbook"
  (cd "$ANS_DIR" && ansible-playbook linux-ws/playbook.yml)
  echo "-- linux-server playbook"
  (cd "$ANS_DIR" && ansible-playbook linux-server/playbook.yml)
fi

echo ""
echo "=========================================="
echo "Готово."
echo "IP:"
echo "  - Linux WS:     $LINUX_WS_IP"
echo "  - Linux Server: $LINUX_SERVER_IP"
echo "=========================================="
