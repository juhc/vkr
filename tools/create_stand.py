#!/usr/bin/env python3
import argparse
import ipaddress
import os
import re
import shutil
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a new stand by copying a base stand and updating examples.")
    parser.add_argument("--base", required=True, help="Base stand directory, e.g. stands/linux-stand")
    parser.add_argument("--name", required=True, help="New stand directory name, e.g. linux-stand-02")
    parser.add_argument("--stand-id", default=None, help="Stand ID/prefix, e.g. stand-02 (defaults to --name)")
    parser.add_argument("--subnet", required=True, help="Subnet CIDR, e.g. 192.168.103.0/24")
    parser.add_argument("--pve-user", default="student01@pve", help="Proxmox user for pool ACL script")
    parser.add_argument("--pve-role", default="StudentVM", help="Proxmox role for pool ACL script")
    parser.add_argument("--out-dir", default="stands", help="Target parent directory (default: stands)")
    return parser.parse_args()


def ip_at(subnet: ipaddress.IPv4Network, offset: int) -> str:
    return str(subnet.network_address + offset)


def replace_tfvar(path: Path, key: str, value: str) -> None:
    content = path.read_text(encoding="utf-8")
    pattern = re.compile(rf'^({re.escape(key)}\s*=\s*)"[^"]*"\s*$', re.MULTILINE)
    if not pattern.search(content):
        raise RuntimeError(f"Key not found in {path}: {key}")
    content = pattern.sub(rf'\1"{value}"', content)
    path.write_text(content, encoding="utf-8")


def replace_tfvar_int(path: Path, key: str, value: str) -> None:
    content = path.read_text(encoding="utf-8")
    pattern = re.compile(rf'^({re.escape(key)}\s*=\s*)\d+\s*$', re.MULTILINE)
    if not pattern.search(content):
        raise RuntimeError(f"Key not found in {path}: {key}")
    content = pattern.sub(rf'\1{value}', content)
    path.write_text(content, encoding="utf-8")


def replace_yaml_value(lines: list[str], key: str, value: str) -> list[str]:
    out = []
    replaced = False
    for line in lines:
        if line.strip().startswith(f"{key}:"):
            out.append(f"{key}: \"{value}\"\n")
            replaced = True
        else:
            out.append(line)
    if not replaced:
        raise RuntimeError(f"Key not found in YAML: {key}")
    return out


def replace_yaml_list(lines: list[str], key: str, items: list[str]) -> list[str]:
    out = []
    i = 0
    found = False
    while i < len(lines):
        line = lines[i]
        if line.strip().startswith(f"{key}:"):
            out.append(f"{key}:\n")
            for item in items:
                out.append(f"  - \"{item}\"\n")
            found = True
            i += 1
            while i < len(lines) and lines[i].lstrip().startswith("- "):
                i += 1
            continue
        out.append(line)
        i += 1
    if not found:
        raise RuntimeError(f"List key not found in YAML: {key}")
    return out


def update_linux_examples(stand_dir: Path, stand_id: str, subnet: ipaddress.IPv4Network) -> None:
    tf_ws = stand_dir / "infrastructure/terraform/linux-ws/terraform.tfvars.example"
    tf_srv = stand_dir / "infrastructure/terraform/linux-server/terraform.tfvars.example"

    replace_tfvar(tf_ws, "linux_ws_name", f"{stand_id}-linux-ws")
    replace_tfvar(tf_ws, "linux_ws_ip", ip_at(subnet, 10))
    replace_tfvar(tf_ws, "gateway", ip_at(subnet, 1))

    replace_tfvar(tf_srv, "linux_server_name", f"{stand_id}-linux-srv")
    replace_tfvar(tf_srv, "linux_server_ip", ip_at(subnet, 20))
    replace_tfvar(tf_srv, "gateway", ip_at(subnet, 1))

    replace_tfvar_int(tf_ws, "cidr_prefix", str(subnet.prefixlen))
    replace_tfvar_int(tf_srv, "cidr_prefix", str(subnet.prefixlen))


def update_windows_examples(stand_dir: Path, stand_id: str, subnet: ipaddress.IPv4Network) -> None:
    tf_ws = stand_dir / "infrastructure/terraform/windows-10/terraform.tfvars.example"
    tf_srv = stand_dir / "infrastructure/terraform/windows-server/terraform.tfvars.example"
    tf_dc = stand_dir / "infrastructure/terraform/domain-controller/terraform.tfvars.example"

    replace_tfvar(tf_ws, "windows_ws_name", f"{stand_id}-windows-10")
    replace_tfvar(tf_ws, "windows_ws_ip", ip_at(subnet, 10))

    replace_tfvar(tf_srv, "windows_server_name", f"{stand_id}-windows-server")
    replace_tfvar(tf_srv, "windows_server_ip", ip_at(subnet, 20))

    replace_tfvar(tf_dc, "dc_name", f"{stand_id}-dc")
    replace_tfvar(tf_dc, "dc_ip", ip_at(subnet, 30))

    ad_example = stand_dir / "infrastructure/ansible/group_vars/all/ad.yml.example"
    if ad_example.exists():
        lines = ad_example.read_text(encoding="utf-8").splitlines(keepends=True)
        lines = replace_yaml_value(lines, "ad_stand_id", stand_id)
        lines = replace_yaml_value(lines, "ad_stand_ou", stand_id.title())
        lines = replace_yaml_value(lines, "ad_dc_ip", ip_at(subnet, 30))
        lines = replace_yaml_list(lines, "ad_stand_computers", [f"{stand_id}-windows-10", f"{stand_id}-windows-server"])
        ad_example.write_text("".join(lines), encoding="utf-8")


def ensure_ansible_vars(stand_dir: Path) -> None:
    group_vars = stand_dir / "infrastructure/ansible/group_vars/all"
    if not group_vars.exists():
        return

    accounts_example = group_vars / "accounts.yml.example"
    accounts_target = group_vars / "accounts.yml"
    if accounts_example.exists() and not accounts_target.exists():
        shutil.copyfile(accounts_example, accounts_target)

    vuln_example = group_vars / "vulnerabilities.yml.example"
    vuln_target = group_vars / "vulnerabilities.yml"
    if vuln_example.exists() and not vuln_target.exists():
        shutil.copyfile(vuln_example, vuln_target)


def write_proxmox_acl_script(stand_dir: Path, stand_id: str, pve_user: str, pve_role: str) -> None:
    scripts_dir = stand_dir / "infrastructure/scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)
    script_path = scripts_dir / "proxmox_pool_acl.sh"
    content = f"""#!/usr/bin/env bash
set -euo pipefail

# Proxmox pool/ACL setup for stand: {stand_id}
# Требуется запуск на ноде Proxmox с правами администратора.

POOL_ID="{stand_id}"
ROLE="{pve_role}"
USER="{pve_user}"

# 1) Роль (минимальные права)
pveum role add "$ROLE" -privs "VM.Audit VM.Console VM.PowerMgmt" || true

# 2) Пользователь (локальный realm pve)
pveum user add "$USER" || true
# pveum passwd "$USER"  # задайте пароль вручную

# 3) Pool
pvesh create /pools -poolid "$POOL_ID" || true

# 4) ACL на pool
pveum aclmod "/pool/$POOL_ID" -user "$USER" -role "$ROLE"

echo "Done. Add your VMIDs to pool: $POOL_ID"
"""
    script_path.write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    base_dir = Path(args.base).resolve()
    out_dir = Path(args.out_dir).resolve()
    new_name = args.name
    stand_id = args.stand_id or args.name

    if not base_dir.exists() or not base_dir.is_dir():
        raise RuntimeError(f"Base stand not found: {base_dir}")
    if not out_dir.exists() or not out_dir.is_dir():
        raise RuntimeError(f"Output parent not found: {out_dir}")

    target_dir = out_dir / new_name
    if target_dir.exists():
        raise RuntimeError(f"Target already exists: {target_dir}")

    subnet = ipaddress.ip_network(args.subnet, strict=False)

    shutil.copytree(base_dir, target_dir)

    if "linux-stand" in base_dir.name:
        update_linux_examples(target_dir, stand_id, subnet)
    elif "windows-stand" in base_dir.name:
        update_windows_examples(target_dir, stand_id, subnet)
    else:
        raise RuntimeError("Base stand name must contain 'linux-stand' or 'windows-stand'")

    ensure_ansible_vars(target_dir)
    write_proxmox_acl_script(target_dir, stand_id, args.pve_user, args.pve_role)

    print(f"OK: created {target_dir}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(2)
