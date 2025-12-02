output "vm_ids" {
  description = "ID виртуальных машин"
  value       = libvirt_domain.vm[*].id
}

output "vm_names" {
  description = "Имена виртуальных машин"
  value       = libvirt_domain.vm[*].name
}

output "vm_ip_addresses" {
  description = "IP адреса виртуальных машин"
  value       = libvirt_domain.vm[*].network_interface[0].addresses
}

output "vm_macs" {
  description = "MAC адреса виртуальных машин"
  value       = libvirt_domain.vm[*].network_interface[0].mac
}

