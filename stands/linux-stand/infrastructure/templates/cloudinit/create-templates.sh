#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

vars_server="$here/variables.cloudinit.linux-server.pkrvars.hcl"
vars_client="$here/variables.cloudinit.linux-client.pkrvars.hcl"

if [[ ! -f "$vars_server" ]]; then
  echo "Создайте $vars_server из variables.cloudinit.linux-server.pkrvars.hcl.example" >&2
  exit 1
fi
if [[ ! -f "$vars_client" ]]; then
  echo "Создайте $vars_client из variables.cloudinit.linux-client.pkrvars.hcl.example" >&2
  exit 1
fi

chmod +x "$here/create-template.sh" >/dev/null 2>&1 || true

echo "== Create linux-server cloud-init template =="
"$here/create-template.sh" -f "$vars_server"

echo "== Create linux-client cloud-init template =="
"$here/create-template.sh" -f "$vars_client"

